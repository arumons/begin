begin = require('..').begin
def = require('..').def
macro = require('..').macro
util = require 'util'

#basic
exports.begin_next_1 = (test) ->
	test.expect(1)
	begin(->
		test.ok true, "this assertion should pass"
		test.done()
		@next())
	.end()

#chain
exports.begin_next_2 = (test) ->
	test.expect(2)
	begin ->
		test.ok true, "one"
		@next()
	._ ->
		test.ok true, "two"
		test.done()
		@next()
	.end()

#argument passing
exports.begin_next_3 = (test) ->
	test.expect(1)
	begin ->
		@next 1
	._ (v) ->
		test.equal v, 1
		test.done()
		@next()
	.end()

#multi argument passing
exports.begin_next_4 = (test) ->
	test.expect(2)
	begin ->
		@next 1, 2
	._ (v1, v2) ->
		test.equal v1, 1
		test.equal v2, 2
		test.done()
		@next()
	.end()

#basic
exports.begin_throw_1 = (test) ->
	test.expect(1)
	begin ->
		@throw()
	.catch ->
		test.ok true, 'catch success'
		test.done()
		@next()
	.end()

#chain
exports.begin_throw_2 = (test) ->
	test.expect 2
	begin ->
		test.ok true, 'one'
		@throw()
	.catch ->
		test.ok 'true', 'two'
		test.done()
		@next()
	.end()

#argument passing
exports.begin_throw_3 = (test) ->
	test.expect(1)
	begin ->
		@throw 1
	.catch (v) ->
		test.equal v, 1
		test.done()
		@next()
	.end()

#multi argument passing
exports.begin_throw_4 = (test) ->
	test.expect 2
	begin ->
		@throw 1, 2
	.catch (v1, v2) ->
		test.equal v1, 1
		test.equal v2, 2
		test.done()
		@next()
	.end()
	
#next and throw mix
exports.next_and_throw_1 = (test) ->
	test.expect 2
	begin ->
		@throw 1, 2
	._ ->
		# never arrive
		throw Error
		@next
	._ ->
		# never arrive
		throw Error
		@throw
	.catch (v1, v2) ->
		test.equal v1, 1
		test.equal v2, 2
		test.done()
		@next()
	.end()

#next and throw mix
exports.next_and_throw_2 = (test) ->
	test.expect 2
	begin ->
		@next 1, 2
	.catch ->
		# never arrive	
		throw error
		@next()
	.catch ->
		# never arrive
		throw error
		@throw()
	._ (v1, v2) ->
		test.equal v1, 1
		test.equal v2, 2
		test.done()
		@next()
	.end()

exports.real_throw_1 = (test) ->
	test.expect 2
	begin(->
		@a = 10
		throw "test")
	.catch((error) ->
		test.equal @a, 10
		test.equal error, "test"
		test.done()
		@next())
	.end()

exports.real_throw_2 = (test) ->
	test.expect 1
	begin(->
		@a = 10
		@next 10)
	._((v) ->
		test.equal @a, 10
		throw "test")
	.catch((error) ->
		#test.equal error, "test"
		test.done()
		@next())
	.end()

#test @ scope
exports.scope_1 = (test) ->
	test.expect 1
	begin(->
		@a = 1
		@next())
	._(->
		test.equal @a, 1
		test.done()
		@next())
	.end()

#test @ scope multi
exports.scope_2 = (test) ->
	test.expect 3
	begin ->
		@a = 1
		@next()
	._ ->
		test.equal @a, 1
		@b = 2
		@next()
	._ ->
		test.equal @a, 1
		test.equal @b, 2
		test.done()
		@next()
	.end()

#inner scope to outer scope with @next
exports.outer_1 = (test) ->
	test.expect 1
	begin ->
		@_ ->
			begin ->
				@next 10
			.end()
	._ (v) ->
		test.equal v, 10
		test.done()
		@next()
	.end()

##inner scope to outer scope with @throw
exports.outer_2 = (test) ->
	test.expect 1
	begin ->
		@_ ->
			begin ->
				@throw 10
			.end()
	.catch (v) ->
		test.equal v, 10
		test.done()
		@next()
	.end()
	
#inner scope can use outer scope
exports.use_outer_scope_1 = (test) ->
	test.expect 2
	begin ->
		@a = 10
		@_ ->
			begin ->
				test.equal @a, 10
				@next()
			.end()
	._ ->
		test.equal @a, 10
		test.done()
		@next()
	.end()

#inner scope can use outer scope
exports.use_outer_scope_2 = (test) ->
	test.expect 2
	begin ->
		@a = 10
		@_ ->
			begin ->
				test.equal @a, 10
				@throw()
			.end()
	.catch ->
		test.equal @a, 10
		test.done()
		@next()
	.end()

#inner scope can use outer scope
exports.use_outer_scope_3 = (test) ->
	test.expect 2
	begin ->
		@a = 10
		@_ ->
			begin ->
				test.equal @a, 10
				@out()
			.end()
	._ ->
		test.equal @a, 10
		test.done()
		@next()
	.end()

#def
exports.def_1 = (test) ->

	t = def ->
			@next 1
		.end()

	begin ->
		@_ -> t()
	._ (v) ->
		test.equal v, 1
		test.done()
		@next()
	.end()

#def with arguments
exports.def_2 = (test) ->
	test.expect 1
	t = def (v) ->
			@next v * 3
		.end()

	begin ->
		@_ -> t 3
	._ (v) ->
		test.equal v, 9
		test.done()
		@next()
	.end()

#def run ather scope
exports.def_3 = (test) ->
	test.expect 1
	t = def((v) ->
			@test = v
			@next())
		.end()

	begin ->
		@_ -> t 10
	._ ->
		test.equal undefined, @test
		test.done()
		@next()
	.end()

#def in def
exports.def_4 = (test) ->
	test.expect 1
	t = def (v) ->
			@next v * 3
		.end()

	t2 = def (v) ->
		 	@_ -> t v
		.end()
	
	begin ->
		@_ -> t2 5
	._ (v) ->
		test.equal v, 15
		test.done()
		@next()
	.end()

# out skip all _ and catch
exports.out_1 = (test) ->
	test.expect 2
	begin(->
		@_ -> begin(->
				@a = 10
				@out())
			._(-> test.ok true, 'not come'; @throw())
			.catch(-> test.ok true, 'not come'; @next())
			.end())
	._ ->
		test.ok true, 'only come'
		test.equal @a, 10
		test.done()
		@next()
	.end()

# receiver inject to @self
exports.def_with_receiver_1 = (test) ->
	test.expect 3
	obj = {a:1,b:2}
	obj.t = def (v) ->
		test.equal v, 10
		test.equal @self.a, 1
		test.equal @self.b, 2
		test.done()
		@next()
	.end()
	obj.t(10)

# filtering value by the provided function
exports.filter_1 = (test) ->
	test.expect 2
	begin ->
		@filter [1,2,3], (v) ->
			@a = 10
			@next v % 2 is 0
	._ (lst) ->
		test.equal @a, 10
		test.deepEqual lst, [2]
		test.done()
		@next()
	.end()

# scope in filter succeed to next scope
exports.filter_2 = (test) ->
	test.expect 1
	begin ->
		@filter [1], (v) ->
			@test = 30
			@next true
	._ (lst) ->
		test.equal @test, 30
		test.done()
		@next()
	.end()

# filter accept defed
exports.filter_3 = (test) ->
	test.expect 2
	a = def (v) ->
			@test = 30
			@next true
		.end()
		
	begin ->
		@filter [5], a
	._ (lst) ->
		test.equal @test, undefined
		test.deepEqual lst, [5]
		test.done()
		@next()
	.end()

# throw called from filter jump to catch
exports.filter_4 = (test) ->
	test.expect 1
	begin ->
		@filter [1], (v) ->
			@throw true
	._ (v) ->
		test.done()
		@next false
	.catch (v) ->
		test.ok v, 'catched'
		test.done()
		@next()
	.end()

 
exports.filter_5 = (test) ->
	test.expect 2
	begin ->
		@_ ->
			begin ->
				@filter [1,2], (v) ->
		        	@out true
			._ (v) ->
				test.deepEqual v, [1,2]
				@next true
			.catch (v) ->
				@next false
			.end()
	._ (v) ->
		test.ok v, 'catched'
		test.done()
		@next()
	.end()

exports.map_1 = (test) ->
	test.expect 2
	begin ->
		@map [1,2,3], (v) ->
			@a = 10
			@next v * 2
	._ (lst) ->
		test.equal @a, 10
		test.deepEqual lst, [2, 4, 6]
		test.done()
		@next()
	.end()

exports.map_2 = (test) ->
	test.expect 2
	begin ->
		@map [1,2,3], (v) ->
			@a = 10
			@next v * 2
	._ (lst) ->
		test.equal @a, 10
		test.deepEqual lst, [2,4,6]
		test.done()
		@next()
	.end()

exports.map_3 = (test) ->
	test.expect 1
	a = def (v) ->
			@next v * v
		.end()

	begin ->
		@map [1,2,3], a
	._ (lst) ->
		test.deepEqual lst, [1,4,9]
		test.done()
		@next()
	.end()

exports.every_1 = (test) ->
	test.expect 1
	begin ->
		@every [1,2,3], (v) ->
			@next v < 5
	._ (v) ->
		test.equal true, v
		test.done()
		@next()
	.end()

exports.every_2 = (test) ->
	test.expect 2
	begin ->
		@every [1,2,3], (v) ->
			@a = 10
			@next v < 2
	._ (v) ->
		test.equal @a, 10
		test.equal v, false
		test.done()
		@next()
	.end()

exports.every_3 = (test) ->
	test.expect 1
	a = def (v) ->
			@next v > 0
		.end()

	begin ->
		@every [1,2,3], a
	._ (v) ->
		test.equal v, true
		test.done()
		@next()
	.end()

exports.some_1 = (test) ->
	test.expect 1
	begin ->
		@some [1,2,3], (v) ->
			@next v is 2
	._ (v) ->
		test.equal true, v
		test.done()
		@next()
	.end()

exports.some_2 = (test) ->
	test.expect 2
	begin ->
		@some [1,2,3], (v) ->
			@a = 10
			@next v > 4
	._ (v) ->
		test.equal @a, 10
		test.equal v, false
		test.done()
		@next()
	.end()

exports.some_3 = (test) ->
	test.expect 1
	a = def (v) ->
			@next v > 2
		.end()

	begin ->
		@some [1,2,3], a
	._ (v) ->
		test.equal v, true
		test.done()
		@next()
	.end()

exports.reduce_1 = (test) ->
	test.expect 1
	begin ->
		@reduce [1,2,3], (pv, cv) ->
			@next pv * cv
	._ (v) ->
		test.equal v, 6
		test.done()
		@next()
	.end()

exports.reduce_2 = (test) ->
	test.expect 2
	begin ->
		@reduce [1,2,3], (pv, cv) ->
			@a = 20
			@next pv * cv
	._ (v) ->
		test.equal @a, 20
		test.equal v, 6
		test.done()
		@next()
	.end()

exports.reduce_3 = (test) ->
	test.expect 2
	f = def (pv, cv) ->
			@a = 10
			@next pv * cv
		.end()

	begin ->
		@reduce [1,2,3], f
	._ (v) ->
		test.equal @a, undefined
		test.equal v, 6
		test.done()
		@next()
	.end()
	

exports.reduceRight_1 = (test) ->
	test.expect 1
	begin ->
		@reduceRight [1,2,3], (pv, cv) ->
			@next pv - cv
	._ (v) ->
		test.equal v, 0
		test.done()
		@next()
	.end()

exports.reduceRight_4 = (test) ->
	test.expect 2
	begin ->
		@reduceRight [1,2,3], (pv, cv) ->
			@a = 10
			@next pv - cv
	._ (v) ->
		test.equal v, 0
		test.equal @a, 10
		test.done()
		@next()
	.end()
