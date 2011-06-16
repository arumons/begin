# This library is a flow control library for node.js and CoffeeScript.
# For more information, please see https://github.com/arumons/begin .

# Manage a scope
class Scope
	constructor: (unit) ->
		jumped = false
		_err_msg = "you can call scope transition function only once in a scope"
		_pre_scope_transition_function = ->
			if jumped
				throw new Error _err_msg
			jumped = true

		# Jump to the next "catch" scope
		@throw = (args...) ->
			_pre_scope_transition_function()
			unit.throw.apply unit, args
			unit

		# Jump to outer scope
		@return = (args...) ->
			_pre_scope_transition_function()
			unit.return.apply unit, args
			unit

		# jump to "_" scope
		@next = (args...) ->
			_pre_scope_transition_function()
			unit.next.apply unit, args
			unit

		@_ = (block) ->
			self = @
			block.call self
			unit

# Manage transitioning to the next scope
class Unit

	# block - executable function.
	# receiver - injection to "@self".
	# use_outer_scope  - if it is true, valiable of outer scope is accesible.
	constructor: (@block, receiver = undefined, @use_outer_scope = true) ->
		@scope = Object.create(new Scope(@))
		@scope.self = receiver

	# Save next scope of outer scope.
	# If scope come end and outer scope exist, transition to outer scope.
	end: ->
		continuation = Units.CurrentContinuation
		@next = (args...) ->
			if @use_outer_scope and continuation?
				@_shift @scope, continuation
			if continuation?
				continuation.next.apply continuation, args
				return
			Units.CurrentContinuation = undefined

		@throw = (args...) ->
			if @use_outer_scope and continuation?
				@_shift @scope, continuation
			if continuation?
				continuation.throw.apply continuation, args
				return
			Units.CurrentContinuation = undefined
			process.nextTick -> throw args[0]

		@return = (args...) ->
			if @use_outer_scope and continuation?
				@_shift @scope, continuation
			if continuation?
				continuation.next.apply continuation, args
				return
			Units.CurrentContinuation = undefined

	# Connect Unit to Unit.
	# Trasition to next scope when @next is called.
	_: (unit) ->
		@next = (args...) ->
			@_next_scope unit, args

		@throw = (args...) ->
			@_skip_scope unit, 'throw', args

		@return = (args...) ->
			@_skip_scope unit, 'return', args

		@next_unit = unit
		unit.previous_unit = @
		return unit

	# Connect Unit to Unit
	# Trasition to next scope when @throw is called.
	catch: (unit) ->
		@next = (args...) ->
			@_skip_scope unit, 'next', args
			
		@throw = (args...) ->
			@_next_scope unit, args

		@return = (args...) ->
			@_skip_scope unit, 'return', args

		@next_unit = unit
		unit.previous_unit = @
		return unit

	# Execute function passed begin or _ or catch.
	invoke: () ->
		if @previous_unit?
			@previous_unit.invoke()
			return

		if @use_outer_scope and Units.CurrentContinuation?
			@_shift Units.CurrentContinuation, @scope

		@_next_scope @, []

	_next_scope: (next_unit, args) ->
		if @ isnt next_unit
			next_unit.use_outer_scope = @use_outer_scope
			@_shift @scope, next_unit.scope
		Units.CurrentContinuation = next_unit.scope
		try
			if next_unit isnt next_unit.block.apply next_unit.scope, args
				throw new Error "you must call scope trasition function at end of scope."
			Units.CurrentContinuation = undefined
		catch error
			@_skip_scope next_unit, 'throw', [error]

	_skip_scope: (next_unit, event, args) ->
		next_unit.use_outer_scope = @use_outer_scope
		@_shift @scope, next_unit.scope
		Units.CurrentContinuation = next_unit.scope
		next_unit[event].apply next_unit, args

	_shift: (from, to) ->
		for own p of from
			to[p] = from[p]

# Utility functions for Array
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

# Provide method for iterator
class ArrayUnits
	_prepare:(block, thisp) ->
		if not thisp?
			thisp = global
		if block.is_defed
			console.log 'come?'
			defed = block
		else
			defed = macro(block).end()
		defed: defed,
		thisp: thisp,
		units: new Units(-> @next()),

	# Returning array which consist of value returned true by the block
	# thisp was injected to @self in the block
	filter: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		result = []
		new Units (_arrays...) ->
			arrays.apply(null, _arrays).each((args...) ->
				units._ (-> @_ -> defed.apply(thisp, args))
				units._((v) -> result.push(args.slice(0, -2)) if v; @next()))
			units._ ->
				@next.apply @, Arrays.zip result
			@_ -> units.end()

	# Returning array which consist of value returned by the block
	# thisp was injected to @self in the block
	each: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		result = []
		new Units (_arrays...) ->
			arrays.apply(null, _arrays).each((args...) ->
				units._ (-> @_ -> defed.apply(thisp, args))
				units._((args...) -> result.push args; @next()))
			units._ ->
				@next.apply @, Arrays.zip result
			@_ -> units.end()

  	# Return true if function return true to all value in the array
	every: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		new Units (array) ->
			array.forEach (item, index, array) ->
				units._((-> @_ -> defed.call(thisp, item, index, array)))
					 ._ (v) ->
							if not v
								@return false
							else
								@next()
			@_ -> units._(-> @return true).end()

	# Return true if function return true to any value in the array
	some: (block, thisp) ->
		{defed, thisp, units} = @_prepare(block, thisp)
		new Units (array) ->
			array.forEach (item, index, array) ->
				units._((-> @_ -> defed.call(thisp, item, index, array)))
					 ._ (v) ->
							if v
							    @return true
							else
								@next()
			@_ -> units._(-> @return false).end()

	# Apply a function an accumulator and each value of the array (left-to-right)
	reduce: (block, init, reverse) ->
		global = (-> this)()
		defed
		if block.is_defed
			defed = block
		else
			defed = macro(block).end()
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
				units._((v1, v2, i, array) -> defed.call global, v1, v2, i, array)
					 ._((v) -> @next v, item, i++, array))
			units._((v1, v2, i, array) -> defed.call global, v1, v2, i, array)
			units._((result) -> @next result).end()

	# Apply a function an accumulator and each value of the array (right-to-left)
	reduceRight: (block, init) ->
		@reduce(block, init, true)

# Manage Units
class Units
	constructor: (block, context = undefined, use_outer_scope = true) ->
		@head = new Unit block, context, use_outer_scope
		@tail = @head

	# "_" and "catch" can receive Unit, Units, Array and function
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
	
	# Define iterators
	for p in ['filter', 'each', 'every', 'some']
		@::[p] = ((p) ->
			(block, thisp) ->
				@_ new ArrayUnits()[p] block, thisp)(p)
		
	# Define iterators
	for p in ['reduce', 'reduceRight']
		@::[p] = ((p) ->
			(block, init) ->
				@_ new ArrayUnits()[p] block, init)(p)

	# Invoke functions from function by passed to "begin"
	end: () ->
		@tail.end()
		@tail.invoke()

# Make freezed Units which is invoked by "()"
# If freezed Units invoked with receiver, receiver is inject to @self.
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
		defed = (args...) ->
					self = @
					begin (->
						@next.apply @, args)
						, self, use_outer_scope
					._(factory())
					.end()
		defed.is_defed = true
		defed

# Receive Array or (block, thisp, use_outer_scope)
begin = (args...) ->
	if Array.isArray args[0]
		new Units((-> @next.apply(@, args)), undefined, true)
	else
		new Units args[0], args[1], args[2]

# Make freezed Units which can't access outer scope.
def = (block) ->
	new Def block

# Make freezed Units which can access outer scope.
macro = (block) ->
	new Def block, true

exports.begin = begin
exports.def = def
exports.macro = macro
