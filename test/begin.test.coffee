begin = require('../..').begin
def = require('../..').def

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
	begin(->
		@next 1 )
	._((v) ->
		test.equal v, 1
		test.done())
	.end()

#multi argument passing
exports.begin_next_4 = (test) ->
	test.expect(2)
	begin(->
		@next 1, 2 )
	._((v1, v2) ->
		test.equal v1, 1
		test.equal v2, 2
		test.done())
	.end()

#basic
exports.begin_throw_1 = (test) ->
	test.expect(1)
	begin(->
		@throw())
	.catch(->
		test.ok true, 'catch success'
		test.done())
	.end()

#chain
exports.begin_throw_2 = (test) ->
	test.expect 2
	begin(->
		test.ok true, 'one'
		@throw())
	.catch(->
		test.ok 'true', 'two'
		test.done())
	.end()

#argument passing
exports.begin_throw_3 = (test) ->
	test.expect(1)
	begin(->
		@throw 1)
	.catch((v) ->
		test.equal v, 1
		test.done())
	.end()

#multi argument passing
exports.begin_throw_4 = (test) ->
	test.expect 2
	begin(->
		@throw 1, 2)
	.catch((v1, v2) ->
		test.equal v1, 1
		test.equal v2, 2
		test.done())
	.end()
	
#next and throw mix
exports.next_and_throw_1 = (test) ->
	test.expect 2
	begin(->
		@throw 1, 2)
	._(->
		# never arrive
		throw Error
		@next)
	._(->
		# never arrive
		throw Error
		@throw)
	.catch((v1, v2) ->
		test.equal v1, 1
		test.equal v2, 2
		test.done()
		@next())
	.end()

#next and throw mix
exports.next_and_throw_2 = (test) ->
	test.expect 2
	begin(->
		@next 1, 2)
	.catch(->
		# never arrive	
		throw error
		@next())
	.catch(->
		# never arrive
		throw error
		@throw())
	._((v1, v2) ->
		test.equal v1, 1
		test.equal v2, 2
		test.done()
		@next())
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
	begin(->
		@a = 1
		@next())
	._(->
		test.equal @a, 1
		@b = 2
		@next())
	._(->
		test.equal @a, 1
		test.equal @b, 2
		test.done()
		@next())
	.end()

#inner scope to outer scope with @next
exports.return_1 = (test) ->
	test.expect 1
	begin(->
		begin(->
			@next 10)
		.end())
	._((v) ->
		test.equal v, 10
		test.done())
	.end()

#inner scope to outer scope with @throw
exports.return_2 = (test) ->
	test.expect 1
	begin(->
		begin(->
			@throw 10)
		.end())
	.catch((v) ->
		test.equal v, 10
		test.done())
	.end()
	
#inner scope can use outer scope
exports.use_outer_scope_1 = (test) ->
	test.expect 2
	begin ->
		@a = 10
		begin ->
			test.equal @a, 10
			@next()
		.end()
	._ ->
		test.equal @a, 10
		test.done()
	.end()

#inner scope can use outer scope
exports.use_outer_scope_2 = (test) ->
	test.expect 2
	begin ->
		@a = 10
		begin ->
			test.equal @a, 10
			@throw()
		.end()
	.catch ->
		test.equal @a, 10
		test.done()
	.end()

#inner scope can use outer scope
exports.use_outer_scope_3 = (test) ->
	test.expect 2
	begin ->
		@a = 10
		begin ->
			test.equal @a, 10
			@return()
		.end()
	._ ->
		test.equal @a, 10
		test.done()
	.end()

#def
exports.def_1 = (test) ->

	t = def ->
			@next 1
		.end()
	begin ->
		t()
	._ (v) ->
		test.equal v, 1
		test.done()
	.end()

#def with arguments
exports.def_2 = (test) ->
	test.expect 1
	t = def (v) ->
			@next v * 3
		.end()

	begin ->
		t 3
	._ (v) ->
		test.equal v, 9
		test.done()
	.end()

#def run ather scope
exports.def_3 = (test) ->
	test.expect 1
	t = def((v) ->
			@test = v
			@next())
		.end()

	begin ->
		t 10
	._ ->
		test.equal undefined, @test
		test.done()
	.end()

#def in def
exports.def_4 = (test) ->
	test.expect 1
	t = def (v) ->
			@next v * 3
		.end()

	t2 = def (v) ->
		 	t v
		.end()
	
	begin ->
		t2 5
	._ (v) ->
		test.equal v, 15
		test.done()
	.end()

# return skip all _ and catch
exports.return_1 = (test) ->
	test.expect 2
	begin(->
		begin(->
			@a = 10
			@return())
		._(-> test.ok true, 'not come'; @throw())
		.catch(-> test.ok true, 'not come'; @next())
		.end())
	._ ->
		test.ok true, 'only come'
		test.equal @a, 10
		test.done()
		@next()
	.end()

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

exports.filter_1 = (test) ->
	test.expect 2
	begin([1, 2, 3]).filter((v) ->
		@a = 10
		@next v % 2 is 0)
	._ (lst) ->
		test.equal @a, 10
		test.deepEqual lst, [2]
		test.done()
	.end()

exports.filter_2 = (test) ->
	test.expect 1
	begin(->
		@next [1,2,3])
	.filter((v) ->
		@next v % 2 is 1)
	._((lst) ->
		test.deepEqual lst, [1, 3]
		test.done())
	.end()

exports.filter_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	._([1,2,3]).filter((v) ->
		@next v % 2 is 1)
	._((lst) ->
		test.deepEqual lst, [1, 3]
		test.done())
	.end()

exports.filter_4 = (test) ->
	test.expect 1
	begin([1]).filter((v) ->
		@test = 30
		@next true)
	._((lst) ->
		test.equal @test, 30
		test.done()
		@next())
	.end()

exports.filter_5 = (test) ->
	test.expect 2
	a = def (v) ->
			@test = 30
			@next true
		.end()
	begin([1]).filter(a)
	._((lst) ->
		test.equal @test, undefined
		test.deepEqual lst, [1]
		test.done()
		@next())
	.end()

exports.each_1 = (test) ->
	test.expect 2
	begin([1, 2, 3]).each((v) ->
		@a = 10
		@next v * 2)
	._((lst) ->
		test.equal @a, 10
		test.deepEqual lst, [2, 4, 6]
		test.done())
	.end()

exports.each_2 = (test) ->
	test.expect 1
	begin(->
		@next [1,2,3])
	.each((v) ->
		@next v * 2)
	._((lst) ->
		test.deepEqual lst, [2,4,6]
		test.done())
	.end()

exports.each_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	._([1,2,3]).each((v) ->
		@next v * 3)
	._((lst) ->
		test.deepEqual lst, [3,6,9]
		test.done())
	.end()

exports.each_4 = (test) ->
	test.expect 2
	begin([1,2,3]).each((v) ->
		@a = 10
		@next v * 2)
	._((lst) ->
		test.equal @a, 10
		test.deepEqual lst, [2,4,6]
		test.done())
	.end()

exports.every_1 = (test) ->
	test.expect 1
	begin([1,2,3]).every((v) ->
		@next v < 5)
	._((v) ->
		test.equal true, v
		test.done())
	.end()

exports.every_2 = (test) ->
	test.expect 1
	begin(->
		@next [1,2,3])
	.every((v) ->
		@next v % 2 is 1)
	._((v) ->
		test.equal false, v
		test.done())
	.end()

exports.every_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	._([1,2,3]).every((v) ->
		@next v < 4)
	._((v) ->
		test.equal true, v
		test.done())
	.end()

exports.every_4 = (test) ->
	test.expect 2
	begin([1,2,3]).every((v) ->
		@a = 10
		@next v < 2)
	._((v) ->
		test.equal @a, 10
		test.equal v, false
		test.done())
	.end()

exports.some_1 = (test) ->
	test.expect 1
	begin([1,2,3]).some((v) ->
		@next v is 2)
	._((v) ->
		test.equal true, v
		test.done())
	.end()

exports.some_2 = (test) ->
	test.expect 1
	begin(->
		@next [1,2,3])
	.some((v) ->
		@next v is 1)
	._((v) ->
		test.equal v, true
		test.done())
	.end()

exports.some_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	._([1,2,3]).some((v) ->
		@next v > 4)
	._((v) ->
		test.equal v, false
		test.done())
	.end()

exports.some_4 = (test) ->
	test.expect 2
	begin([1,2,3]).some((v) ->
		@a = 10
		@next v > 4)
	._((v) ->
		test.equal @a, 10
		test.equal v, false
		test.done())
	.end()

exports.reduce_1 = (test) ->
	test.expect 1
	begin([1,2,3]).reduce((pv, cv) ->
		@next pv * cv)
	._((v) ->
		test.equal v, 6
		test.done())
	.end()

exports.reduce_2 = (test) ->
	test.expect 1
	begin(->
		@next [1,2,3])
	.reduce(((pv, cv) ->
		@next pv * cv), 4)
	._((v) ->
		test.equal v, 24
		test.done())
	.end()

exports.reduce_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	._([1,2,3]).reduce((pv, cv) ->
		@next pv * cv
	, 4)
	._((v) ->
		test.equal v, 24
		test.done())
	.end()

exports.reduce_4 = (test) ->
	test.expect 2
	begin([1,2,3]).reduce((pv, cv) ->
		@a = 20
		@next pv * cv)
	._((v) ->
		console.log 4, @
		test.equal @a, 20
		test.equal v, 6
		test.done())
	.end()

exports.reduce_5 = (test) ->
	test.expect 2
	f = def (pv, cv) ->
			console.log 'def', @
			@a = 10
			@next pv * cv
		.end()

	begin([1,2,3]).reduce(f)
	._ (v) ->
		console.log @
		test.equal @a, undefined
		test.equal v, 6
		test.done()
		@next()
	.end()
	

exports.reduceRight_1 = (test) ->
	test.expect 1
	begin([1,2,3]).reduceRight((pv, cv) ->
		@next pv - cv)
	._((v) ->
		test.equal v, 0
		test.done())
	.end()

exports.reduceRight_2 = (test) ->
	test.expect 1
	begin(->
		@next [1,2,3])
	.reduceRight((pv, cv) ->
		@next pv - cv
	, 4)
	._((v) ->
		test.equal v, -2
		test.done())
	.end()

exports.reduceRight_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	._([1,2,3,4]).reduceRight((pv, cv) ->
		@next pv - cv)
	._((v) ->
		test.equal v, -2
		test.done())
	.end()

exports.reduceRight_4 = (test) ->
	test.expect 2
	begin([1,2,3]).reduceRight((pv, cv) ->
		@a = 10
		@next pv - cv)
	._((v) ->
		test.equal v, 0
		test.equal @a, 10
		test.done())
	.end()
