{begin, def} = require '../src/begin'
fs = require 'fs'

files = process.argv.slice 2

begin(files).each (file) ->
	fs.readFile file, 'utf8', @next
.each (error, data) ->
	process.stdout.write data
	@next()
.end()
