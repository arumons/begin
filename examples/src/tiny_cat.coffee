{begin, def} = require '../..'
fs = require 'fs'

files = process.argv.slice 2

begin(files).each (file) ->
	@_ -> fs.readFile file, 'utf8', @next
.each (error, data) ->
	process.stdout.write data
	@next()
.end()
