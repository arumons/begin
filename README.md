# begin

Flow control library for node.js and CoffeeScript

Features ..

 - OOP support.
 - Provide several scope transition functions.

# Quick Exmaples

	{begin, def} = require 'begin.js'
	fs = require 'fs'

	# example 1
	begin ->
		@_ -> fs.readFile '/etc/passwd', @next
	._ (data) ->
		console.log data
		@next()
	.end()

	# example 2
	begin ->
		if flg
			return @throw # jump to #1
		@next() # jump to #2
	.catch (err) -> # 1
		# if flg is true, this statement is executed.
		console.log err
		@next() # jump to #2
	._ -> # 2
		#...
		@next()
	.end()

	# example 3
	begin ->
		@_ ->
			begin ->
				switch state
					when "ok" then @next 1 # jump to #1
					when "error" then @throw "2" # jumtp to #2
					when "end" then @out "3" # jumtp to #3
					else @throw 4 # jumtp to #2
			._ (data) -> #1
				# data is 1
				@next 4 # jumtp to #3
			.catch (err) -> #2
				# data is 2
				@next 5 # jumtp to #3
			.end()
	._ (data) -> #3
		# data is 3 or 4 or 5 
		@next()
	.end()

	# exapmple 4
	f = def (file) ->
			@_ -> fs.readFile file, @next
		.end()

	begin ->
		@_ -> f()
	._ (data) ->
		console.log data
		@next()
	.end()

	# exapmle 5
	obj = {name: "bob"}
	obj.f = def (file) ->
				@_ -> fs.writeFile file, @self.name, @next
			._ (err) ->
				throw err if err
				@_ -> fs.writeFile file, @self.age, @next
			.end()

	begin ->
		@_ -> obj.f()
	._ (err) ->
		throw err if err
		@next()
	.end()

# Install

	npm install begin.js

# APIs

## Core
 - begin
 - _     
 - catch
 - end
 - def
 - @`_`
 - @next
 - @throw
 - @out

begin library connect each asyncronous processing.
Connecting is done by passing @next or @throw or @out.
If @next called, process jump to next "`_`" scope.
@throw called, process jump to next "catch" scope.
@out called, process jump to outer "`_`" scope.
Please look at the examples above.
Note each transition functions(@next, @throw, @out) must be called end of scope.
This rule prevent that processing is made a spaghetti.
If transition functions can't call end of socpe, use @_ like example below.

	# bad case
	begin ->
		@next()
		console.log # NG!! Exception will be thrown!
	._ ->
		@next()
	.end()

	# good case
	begin ->
		console.log "test"
		@next() # OK
	._ ->
		@next()
	.end()

	# bad case2
	begin ->
		fs.readFile "/etc/passwd", @next # NG!! The final processing of the scope is readFile rather than @next...
	._ (data) ->
		# It will not come here...
		console.log data
		@next()
	.end()

	# good case2 (use @_)
	begin ->
		@_ -> fs.readFile "/etc/passwd", @next # OK
	._ (data) ->
		console.log data
		@next()
	.end()

## Iterator
In begin scope, iterators following is available.

 - @filter
 - @map
 - @every
 - @some
 - @reduce
 - @reduceRight

begin library provide iterator functions for asyncronous processing.
Interface of iterator is same iterator of javascript.
Please look at the examples below and document of iteration methods at mdn (https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array)

	# @filter
	begin ->
		@filter [1,2,3], (v) ->
			@next v % 2 is 0
	._ (lst) ->
		lst # [2]
		@next()
	.end()

	# @map
	begin ->
		@map [1,2,3], (v) ->
			@next v * 2
	._ (lst) ->
		lst # [2,4,6]
		@next()
	.end()

	# @every
	begin ->
		@every [1,2,3], (v) ->
			@next v < 4
	._ (result) ->
		result # true
		@next()
	.end()
	
	# @some
	begin ->
		@some [1,2,3], (v) ->
			@next v < 2
	._ (result) ->
		result # true
		@next()
	.end()

	# @reduce
	begin ->
		@reduce [1,2,3], (pv, cv) ->
			@next pv - cv
	._ (result) ->
		result # -4
		@next()
	.end()

	# @reduceRight
	begin ->
		@reduceRight [1,2,3], (pv, cv) ->
			@next pv - cv
	._ (result) ->
		result # 0
		@next()
	.end()
