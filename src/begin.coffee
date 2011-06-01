events = require 'events'
util = require 'util'

class Scope
	constructor: (@unit, @self) ->
		self = @
		@next = (args...) ->
			self._next.apply self, args
		@throw = (args...) ->
			self._throw.apply self, args
		@return = (args...) ->
			self._return.apply self, args

	_next: (args...) ->
		args.unshift('next')
		@unit.emit.apply(@unit, args)

	_throw: (args...) ->
		args.unshift('throw')
		@unit.emit.apply(@unit, args)

	_return: (args...) ->
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
				process.nextTick ->
					throw args[0]

		@on 'return', (args...) ->
			if succeed and continuation?
				@_shift @scope, continuation
			if continuation?
				continuation.next.apply(continuation, args)
			else
				Units.CurrentContinuation = undefined

	_: (unit) ->
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


arrays = (arrays...) ->
	new Arrays arrays

class Arrays
	constructor: (arrays) ->
		@ziped = Arrays.zip arrays

	@zip: (arrays) ->
		max = 0
		arrays.forEach (array) ->
			len = array.length
			max = len if max < len

		line = []
		for i in [0...max]
			line.push arrays.map (v) ->
							v[""+i]
		line

	each: (block, thisp) ->
		result = []
		if not thisp?
			thisp = global
		@ziped.map (args, i, _array) ->
			args.push i
			args.push _array
			result.push block.apply(thisp, args)
		result


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
		new Units (_arrays...) ->
			arrays.apply(null, _arrays).each((args...) ->
				units._(defed.apply(thisp, args))
				units._((v) -> result.push(args.slice(0, -2)) if v; @next()))
			units._ ->
				@next.apply @, Arrays.zip result
			units.end true

	each: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		result = []
		new Units (_arrays...) ->
			arrays.apply(null, _arrays).each((args...) ->
				units._(defed.apply(thisp, args))
				units._((args...) -> result.push args; @next()))
			units._ ->
				@next.apply @, Arrays.zip result
			units.end true

	every: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		new Units (array) ->
			units = new Units(-> @next())
			array.forEach (item, index, array) ->
				units._(defed.call(thisp, item, index, array))
					 ._ (v) ->
							if not v
								@return false
							else
								@next()
			units._(-> @return true).end(true)

	some: (block, thisp) ->
		{defed, thisp, unit} = @_prepare(block, thisp)
		new Units (array) ->
			units = new Units(-> @next())
			array.forEach (item, index, array) ->
				units._(defed.call(thisp, item, index, array))
					 ._ (v) ->
							if v
							    @return true
							else
								@next()
			units._(-> @return false).end(true)

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
				units._(-> @next init, array[0], i++, array)
				_array = array.slice(1)
			else
				i++
				units._(-> @next array[0], array[1], i++, array)
				_array = array.slice(2)

			_array.forEach((item) ->
				units._(block)
					 ._((v) -> @next v, item, i++, array))
			units._(block)
			units._((result) -> @next result).end(true)

	reduceRight: (block, init) ->
		@reduce(block, init, true)


class Units
	constructor: (block, context, succeed) ->
		@head = new Unit(block, context, succeed)
		@tail = @head
		@is_units = true
	
	_: (block, context) ->
		if block.is_unit
			@tail = @tail._(block)
		else if block.is_units
			@tail._(block.head)
			@tail = block.tail
		else if block.is_defed or block.is_macro
			units = block()
			@tail = @tail._(units.head)
			@tail = units.tail
		else if Array.isArray block
			@tail = @tail._(new Unit(-> @next block))
		else
			@tail = @tail._(new Unit(block, context))
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
		@_ new ArrayUnits().filter(block, thisp)

	each: (block, thisp) ->
		@_ new ArrayUnits().each(block, thisp)

	every: (block, thisp) ->
		@_ new ArrayUnits().every(block, thisp)
	
	some: (block, thisp) ->
		@_ new ArrayUnits().some(block, thisp)
	
	reduce: (block, init) ->
		@_ new ArrayUnits().reduce(block, init)

	reduceRight: (block, init) ->
		@_ new ArrayUnits().reduceRight(block, init)


begin = (args...) ->
	if Array.isArray args[0]
		new Units((-> @next.apply(@, args)), undefined, true)
	else
		new Units(args[0], undefined, true)

macro = (block) ->
	defed = (args...) ->
				args = [] if args.length is 0
				units = new Units (->
					@next.apply(@, args))
				return units._(block, @)
	defed.is_macro = true
	return defed

def = (block) ->
	defed = (args...) ->
		args = [] if args.length is 0
		self = @
		units = new Units(->
			begin(->
				@next.apply(@, args))
			._(block, self)
			.end())
	defed.is_defed = true
	return defed

exports.begin = begin
exports.def = def
