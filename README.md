# begin

Flow control library for node.js and CoffeeScript

# Quick Exmaples

	{begin, def} = require 'begin'
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

# Documentation

## Core
 - begin
 - _
 - catch
 - end
 - def

## Iterator
 - filter
 - map
 - every
 - some
 - reduce
 - reduceRight


