events = require 'events'
util = require 'util'

class Scope
	constructor: (@unit) ->
		self = @
		
		@throw= (args...) ->
			args.unshift 'throw'
			self.unit.emit.apply self.unit, args

		@return = (args...) ->
			args.unshift 'return'
			self.unit.emit.apply self.unit, args

		@next = (args...) ->
			args.unshift 'next'
			self.unit.emit.apply self.unit, args

class Unit extends events.EventEmitter
	constructor: (@block, receiver = undefined, @use_outer_scope = true) ->
		@scope = Object.create(new Scope(@))
		@scope.self = receiver
		events.EventEmitter.call @

	end: ->
		continuation = Units.CurrentContinuation
		@on 'next', (args...) ->
			if @use_outer_scope and continuation?
				@_shift @scope, continuation
			if continuation?
				continuation.next.apply continuation, args
				return
			Units.CurrentContinuation = undefined

		@on 'throw', (args...) ->
			if @use_outer_scope and continuation?
				@_shift @scope, continuation
			if continuation?
				continuation.throw.apply(continuation, args)
				return
			Units.CurrentContinuation = undefined
			process.nextTick -> throw args[0]

		@on 'return', (args...) ->
			if @use_outer_scope and continuation?
				@_shift @scope, continuation
			if continuation?
				continuation.next.apply(continuation, args)
				return
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
			return

		if @use_outer_scope and Units.CurrentContinuation?
			@_shift Units.CurrentContinuation, @scope

		Units.CurrentContinuation = @scope

		try
			@block.call @scope
		catch error
			@_skip_scope @, 'throw', [error]

	_next_scope: (next_unit, args) ->
		next_unit.use_outer_scope = @use_outer_scope
		@_shift @scope, next_unit.scope
		Units.CurrentContinuation = next_unit.scope
		try
			next_unit.block.apply(next_unit.scope, args)
		catch error
			@_skip_scope next_unit, 'throw', [error]

	_skip_scope: (next_unit, event, args) ->
		next_unit.use_outer_scope = @use_outer_scope
		@_shift @scope, next_unit.scope
		Units.CurrentContinuation = next_unit.scope
		args.unshift(event)
		next_unit.emit.apply(next_unit, args)

	_shift: (from, to) ->
		for own p of from
			to[p] = from[p]

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
			defed = macro(block).end()
		defed: defed,
		thisp: thisp,
		units: new Units(-> @next()),

	filter: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		result = []
		new Units (_arrays...) ->
			arrays.apply(null, _arrays).each((args...) ->
				units._ (-> defed.apply(thisp, args))
				units._((v) -> result.push(args.slice(0, -2)) if v; @next()))
			units._ ->
				@next.apply @, Arrays.zip result
			units.end()

	each: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		result = []
		new Units (_arrays...) ->
			arrays.apply(null, _arrays).each((args...) ->
				units._ (-> defed.apply(thisp, args))
				units._((args...) -> result.push args; @next()))
			units._ ->
				@next.apply @, Arrays.zip result
			units.end()

	every: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		new Units (array) ->
			units = new Units(-> @next())
			array.forEach (item, index, array) ->
				units._((-> defed.call(thisp, item, index, array)))
					 ._ (v) ->
							if not v
								@return false
							else
								@next()
			units._(-> @return true).end()

	some: (block, thisp) ->
		{defed, thisp, unit} = @_prepare(block, thisp)
		new Units (array) ->
			units = new Units(-> @next())
			array.forEach (item, index, array) ->
				units._((-> defed.call(thisp, item, index, array)))
					 ._ (v) ->
							if v
							    @return true
							else
								@next()
			units._(-> @return false).end()

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
			units._((result) -> @next result).end()

	reduceRight: (block, init) ->
		@reduce(block, init, true)


class Units
	constructor: (block, context = undefined, use_outer_scope = true) ->
		@head = new Unit block, context, use_outer_scope
		@tail = @head

	for p in ['_', 'catch']
		@::[p] = ((p) ->
			(block) ->
				if block instanceof Unit
					@tail = @tail[p] block
				else if block instanceof Units
					@tail[p] block.head
					@tail = block.tail
				else if Array.isArray block
					@tail = @tail[p] new Unit -> @next block
				else
					@tail = @tail[p](new Unit block)
				return @)(p)
	
	for p in ['filter', 'each', 'every', 'some']
		@::[p] = ((p) ->
			(block, thisp) ->
				@_ new ArrayUnits()[p] block, thisp)(p)
		
	for p in ['reduce', 'reduceRight']
		@::[p] = ((p) ->
			(block, init) ->
				@_ new ArrayUnits()[p] block, init)(p)

	end: () ->
		@tail.end()
		@tail.invoke()

class Def
	constructor: (block, @use_outer_scope = false) ->
		@factory = -> new Units block

	for p in ['_', 'catch', 'each', 'filter', 'every', 'some']
		@::[p] = ((p) ->
			(block) ->
				previous_factory = @factory
				@factory = ->
					previous_factory()[p] block
				@)(p)

	for p in ['reduce', 'reduceRight']
		@::[p] = ((p) ->
			(block, init) ->
				previous_factory = @factory
				@factory = ->
					previous_factory()[p] block, init
				@)(p)

	end: ->
		factory = @factory
		use_outer_scope = @use_outer_scope
		(args...) ->
			self = @
			begin (->
				@next.apply @, args)
				, self, use_outer_scope
			._(factory())
			.end()

begin = (args...) ->
	if Array.isArray args[0]
		new Units((-> @next.apply(@, args)), undefined, true)
	else
		new Units args[0], args[1], args[2]

def = (block) ->
	new Def block

macro = (block) ->
	new Def block, true

exports.begin = begin
exports.def = def
exports.macro = macro
