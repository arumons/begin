events = require('events')
util = require('util')

class Scope
	constructor: (@unit, @self) ->
	
	next: (args...) ->
		args.unshift('next')
		@unit.emit.apply(@unit, args)

	throw: (args...) ->
		args.unshift('throw')
		@unit.emit.apply(@unit, args)

	return: (args...) ->
		args.unshift('return')
		@unit.emit.apply(@unit, args)

class Unit extends events.EventEmitter
	constructor: (@block, receiver, @succeed) ->
		@is_unit = true
		@scope = Object.create(new Scope(@, receiver))
		events.EventEmitter.call(@)

	end: (succeed) ->
		continuation = Units.CurrentContinuation
		@on 'next', (args...) ->
			if succeed and continuation?
				@_shift @scope, continuation
			if continuation?
				continuation.next.apply(continuation, args)
			else
				Units.CurrentContinuation = undefined

		@on 'throw', (args...) ->
			if succeed and continuation?
				@_shift @scope, continuation
			if continuation?
				continuation.throw.apply(continuation, args)
			else
				Units.CurrentContinuation = undefined

		@on 'return', (args...) ->
			if succeed and continuation?
				@_shift @scope, continuation
			if continuation?
				continuation.next.apply(continuation, args)
			else
				Units.CurrentContinuation = undefined

	then: (unit) ->
		@on('next', (args...) ->
			@_next_scope(unit, args))

		@on('throw', (args...) ->
			@_skip_scope(unit, 'throw', args))

		@on('return', (args...) ->
			@_skip_scope(unit, 'return', args))

		@next_unit = unit
		unit.previous_unit = @
		return unit

	catch: (unit) ->
		@on('next', (args...) ->
			@_skip_scope(unit, 'next', args))
			
		@on('throw', (args...) ->
			@_next_scope(unit, args))

		@on('return', (args...) ->
			@_skip_scope(unit, 'return', args))

		@next_unit = unit
		unit.previous_unit = @
		return unit

	invoke: () ->
		if @previous_unit?
			@previous_unit.invoke()
		else
			if @succeed? and Units.CurrentContinuation?
				@_succeed Units.CurrentContinuation

			Units.CurrentContinuation = @scope

			try
				@block.call(@scope)
			catch error
				@_skip_scope @, 'throw', [error]

	_succeed: (outer_scope) ->
		for own key of outer_scope
			@_set_property(key, outer_scope)

	_set_property: (name, outer_scope) ->
		Object.defineProperty(@scope, name,
			get: -> outer_scope[name],
			set: (v) -> outer_scope[name] = v)

	
	_next_scope: (next_unit, args) ->
		@_shift(@scope, next_unit.scope)
		Units.CurrentContinuation = next_unit.scope
		try
			next_unit.block.apply(next_unit.scope, args)
		catch error
			@_skip_scope next_unit, 'throw', [error]

	_skip_scope: (next_unit, event, args) ->
		@_shift(@scope, next_unit.scope)
		Units.CurrentContinuation = next_unit.scope
		args.unshift(event)
		next_unit.emit.apply(next_unit, args)

	_shift: (a, b) ->
		for own key of a
			b[key] = a[key]


class ArrayUnits
	_prepare:(block, thisp) ->
		if not thisp?
			thisp = global
		if block.is_defed
			defed = block
		else
			defed = macro(block)
		defed: defed,
		thisp: thisp,
		units: new Units(-> @next()),

	filter: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		result = []
		new Units (array) ->
			array.forEach((item, index, array) ->
				units.then(defed.call(thisp, item, index, array))
					 .then((v) -> result.push(item) if v; @next()))
			units.then ->
				@next result
			units.end(true)

	each: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		result = []
		new Units (array) ->
			array.forEach((item, index, array) ->
				units.then(defed.call(thisp, item, index, array))
				     .then((v) -> result.push(v); @next()))
			units.then(->
				@next result)
			units.end(true)

	every: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		new Units (array) ->
			units = new Units(-> @next())
			array.forEach (item, index, array) ->
				units.then(defed.call(thisp, item, index, array))
					 .then (v) ->
							if not v
								@return false
							else
								@next()
			units.then(-> @return true).end(true)

	some: (block, thisp) ->
		{defed, thisp, unit} = @_prepare(block, thisp)
		new Units (array) ->
			units = new Units(-> @next())
			array.forEach (item, index, array) ->
				units.then(defed.call(thisp, item, index, array))
					 .then (v) ->
							if v
							    @return true
							else
								@next()
			units.then(-> @return false).end(true)

	reduce: (block, init, reverse) ->
		new Units (array) ->
			i = 0
			units = new Units ->
				if array.length is 0
					@throw new TypeError()
				else
					@next()
			array = array.reverse() if reverse
			if init?
				units.then(-> @next init, array[0], i++, array)
				_array = array.slice(1)
			else
				i++
				units.then(-> @next array[0], array[1], i++, array)
				_array = array.slice(2)

			_array.forEach((item) ->
				units.then(block)
					 .then((v) -> @next v, item, i++, array))
			units.then(block)
			units.then((result) -> @next result).end(true)

	reduceRight: (block, init) ->
		@reduce(block, init, true)


class Units
	constructor: (block, context, succeed) ->
		@head = new Unit(block, context, succeed)
		@tail = @head
		@is_units = true
	
	then: (block, context) ->
		if block.is_unit
			@tail = @tail.then(block)
		else if block.is_units
			@tail.then(block.head)
			@tail = block.tail
		else if block.is_defed or block.is_macro
			units = block()
			@tail = @tail.then(units.head)
			@tail = units.tail
		else if Array.isArray block
			@tail = @tail.then(new Unit(-> @next block))
		else
			@tail = @tail.then(new Unit(block, context))
		return @

	catch: (block, context) ->
		if block.is_unit
			@tail = @tail.catch(block)
		else if block.is_units
			@tail.catch(block.head)
			@tail = block.tail
		else if block.is_defed
			units = block()
			@tail = @tail.catch(units.head)
			@tail = units.tail
		else if Array.isArray block
			@tail = @tail.catch(new Unit(-> @next block))
		else
			@tail = @tail.catch(new Unit(block, context))
		return @
	
	end: (succeed) ->
		@tail.end(succeed)

		@tail.invoke()
		
	filter: (block, thisp) ->
		@then new ArrayUnits().filter(block, thisp)

	each: (block, thisp) ->
		@then new ArrayUnits().each(block, thisp)

	every: (block, thisp) ->
		@then new ArrayUnits().every(block, thisp)
	
	some: (block, thisp) ->
		@then new ArrayUnits().some(block, thisp)
	
	reduce: (block, init) ->
		@then new ArrayUnits().reduce(block, init)

	reduceRight: (block, init) ->
		@then new ArrayUnits().reduceRight(block, init)


begin = (block) ->
	if Array.isArray block
		new Units((-> @next block), undefined, true)
	else
		new Units(block, undefined, true)

macro = (block) ->
	defed = (args...) ->
				args = [] if args.length is 0
				units = new Units (->
					@next.apply(@, args))
				return units.then(block, @)
	defed.is_macro = true
	return defed

def = (block) ->
	defed = (args...) ->
		args = [] if args.length is 0
		self = @
		units = new Units(->
			begin(->
				@next.apply(@, args))
			.then(block, self)
			.end())
	defed.is_defed = true
	return defed

exports.begin = begin
exports.def = def
