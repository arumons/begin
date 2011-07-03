# begin

Flow control library for node.js and CoffeeScript

# Quick Exmaples

	{begin} = require 'begin'
	fs = require 'fs'

	begin ->
		@_ -> fs.readFile '/etc/passwd', @next
	._ (data) ->
		console.log data
	.end()


