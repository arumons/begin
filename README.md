# begin

Flow control library for node.js and CoffeeScript

# Quick Exmaples

	{begin} = require 'begin'
	fs = require 'fs'

	begin ->
		@_ -> fs.readFile '/tec/passwd', @next
	._ (data) ->
		console.log data
	.end()


