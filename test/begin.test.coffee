util = require('util')
begin = require('../src/begin').begin
def = require('../src/begin').def

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
	begin(->
		test.ok true, "one"
		@next())
	.then(->
		test.ok true, "two"
		test.done()
		@next())
	.end()

#argument passing
exports.begin_next_3 = (test) ->
	test.expect(1)
	begin(->
		@next 1 )
	.then((v) ->
		test.equal v, 1
		test.done())
	.end()

#multi argument passing
exports.begin_next_4 = (test) ->
	test.expect(2)
	begin(->
		@next 1, 2 )
	.then((v1, v2) ->
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
	.then(-> @next)
	.then(-> @throw)
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
	.catch(-> @next())
	.catch(-> @throw())
	.then((v1, v2) ->
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
	.then((v) ->
		test.equal @a, 10
		throw "test")
	.catch((error) ->
		console.log error
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
	.then(->
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
	.then(->
		test.equal @a, 1
		@b = 2
		@next())
	.then(->
		test.equal @a, 1
		test.equal @b, 2
		test.done()
		@next())
	.end()

exports.scope_3 = (test) ->
	test.expect 2
	begin(->
		@a = 10
		begin(->
			test.equal @a, 10
			@a = 30
			@next())
		.end())
	.then(->
		test.equal @a, 30
		test.done()
		@next())
	.end()

#next to return
exports.return_1 = (test) ->
	test.expect 1
	begin(->
		begin(->
			@next 10)
		.end(@return))
	.then((v) ->
		test.equal v, 10
		test.done())
	.end()

#throw to return
exports.return_2 = (test) ->
	test.expect 1
	begin(->
		begin(->
			@throw 10)
		.end(@return))
	.catch((v) ->
		test.equal v, 10
		test.done())
	.end()

#def
exports.def_1 = (test) ->
	test.expect 1
	t = def(->
			@next 1)
	t()
	.then((v) -> test.equal v, 1; test.done())
	.end()

#def with arguments
exports.def_2 = (test) ->
	test.expect 1
	t = def((v) ->
			@next v * 3)
	t(3)
	.then((v) -> test.equal v, 9; test.done())
	.end()

#def run ather scope
exports.def_3 = (test) ->
	test.expect 1
	t = def((v) ->
			@test = 3
			@next())
	t()
	.then(-> test.equal undefined, @test; test.done())
	.end()

# return skip all then and catch
exports.return_1 = (test) ->
	test.expect 2
	begin(->
		begin(->
			@a = 10
			@return())
		.then(-> test.ok true, 'not come'; @throw())
		.catch(-> test.ok true, 'not come'; @next())
		.end())
	.then(->
		test.ok true, 'only come'
		test.equal @a, undefined
		test.done()
		@next())
	.end()

exports.def_with_receiver_1 = (test) ->
	test.expect 3
	obj = {a:1,b:2}
	obj.t = def((v) ->
		test.equal v, 10
		test.equal @self.a, 1
		test.equal @self.b, 2
		test.done()
		@next())
	obj.t(10).end()

exports.filter_1 = (test) ->
	test.expect 2
	begin([1, 2, 3]).filter((v) ->
		@a = 10
		@next v % 2 is 0)
	.then((lst) ->
		test.equal @a, 10
		test.deepEqual lst, [2]
		test.done())
	.end()

exports.filter_2 = (test) ->
	test.expect 1
	begin(->
		@next [1,2,3])
	.filter((v) ->
		@next v % 2 is 1)
	.then((lst) ->
		test.deepEqual lst, [1, 3]
		test.done())
	.end()

exports.filter_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	.then([1,2,3]).filter((v) ->
		@next v % 2 is 1)
	.then((lst) ->
		test.deepEqual lst, [1, 3]
		test.done())
	.end()

exports.filter_4 = (test) ->
	test.expect 1
	begin([1]).filter((v) ->
		@test = 30
		@next true)
	.then((lst) ->
		test.equal @test, 30
		test.done()
		@next())
	.end()

exports.filter_5 = (test) ->
	test.expect 2
	a = def (v) ->
		@test = 30
		@next true
	begin([1]).filter(a)
	.then((lst) ->
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
	.then((lst) ->
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
	.then((lst) ->
		test.deepEqual lst, [2,4,6]
		test.done())
	.end()

exports.each_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	.then([1,2,3]).each((v) ->
		@next v * 3)
	.then((lst) ->
		test.deepEqual lst, [3,6,9]
		test.done())
	.end()

exports.each_4 = (test) ->
	test.expect 2
	begin([1,2,3]).each((v) ->
		@a = 10
		@next v * 2)
	.then((lst) ->
		test.equal @a, 10
		test.deepEqual lst, [2,4,6]
		test.done())
	.end()

exports.every_1 = (test) ->
	test.expect 1
	begin([1,2,3]).every((v) ->
		@next v < 5)
	.then((v) ->
		test.equal true, v
		test.done())
	.end()

exports.every_2 = (test) ->
	test.expect 1
	begin(->
		@next [1,2,3])
	.every((v) ->
		@next v % 2 is 1)
	.then((v) ->
		test.equal false, v
		test.done())
	.end()

exports.every_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	.then([1,2,3]).every((v) ->
		@next v < 4)
	.then((v) ->
		test.equal true, v
		test.done())
	.end()

exports.every_4 = (test) ->
	test.expect 2
	begin([1,2,3]).every((v) ->
		@a = 10
		@next v < 2)
	.then((v) ->
		test.equal @a, 10
		test.equal v, false
		test.done())
	.end()

exports.some_1 = (test) ->
	test.expect 1
	begin([1,2,3]).some((v) ->
		@next v is 2)
	.then((v) ->
		test.equal true, v
		test.done())
	.end()

exports.some_2 = (test) ->
	test.expect 1
	begin(->
		@next [1,2,3])
	.some((v) ->
		@next v is 1)
	.then((v) ->
		test.equal v, true
		test.done())
	.end()

exports.some_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	.then([1,2,3]).some((v) ->
		@next v > 4)
	.then((v) ->
		test.equal v, false
		test.done())
	.end()

exports.some_4 = (test) ->
	test.expect 2
	begin([1,2,3]).some((v) ->
		@a = 10
		@next v > 4)
	.then((v) ->
		test.equal @a, 10
		test.equal v, false
		test.done())
	.end()

exports.reduce_1 = (test) ->
	test.expect 1
	begin([1,2,3]).reduce((pv, cv) ->
		@next pv * cv)
	.then((v) ->
		test.equal v, 6
		test.done())
	.end()

exports.reduce_2 = (test) ->
	test.expect 1
	begin(->
		@next [1,2,3])
	.reduce(((pv, cv) ->
		@next pv * cv), 4)
	.then((v) ->
		test.equal v, 24
		test.done())
	.end()

exports.reduce_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	.then([1,2,3]).reduce((pv, cv) ->
		@next pv * cv
	, 4)
	.then((v) ->
		test.equal v, 24
		test.done())
	.end()

exports.reduce_4 = (test) ->
	test.expect 2
	begin([1,2,3]).reduce((pv, cv) ->
		@a = 10
		@next pv * cv)
	.then((v) ->
		test.equal @a, 10
		test.equal v, 6
		test.done())
	.end()
	

exports.reduceRight_1 = (test) ->
	test.expect 1
	begin([1,2,3]).reduceRight((pv, cv) ->
		@next pv - cv)
	.then((v) ->
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
	.then((v) ->
		test.equal v, -2
		test.done())
	.end()

exports.reduceRight_3 = (test) ->
	test.expect 1
	begin(->
		@next 100)
	.then([1,2,3,4]).reduceRight((pv, cv) ->
		@next pv - cv)
	.then((v) ->
		test.equal v, -2
		test.done())
	.end()

exports.reduceRight_4 = (test) ->
	test.expect 2
	begin([1,2,3]).reduceRight((pv, cv) ->
		@a = 10
		@next pv - cv)
	.then((v) ->
		test.equal v, 0
		test.equal @a, 10
		test.done())
	.end()
