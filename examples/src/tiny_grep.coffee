{begin, def} = require '../src/begin'
fs = require 'fs'

pattern = process.argv[2]
files = process.argv[3]

begin(files).each (file) ->
	fs.readFile file, 'utf8', @next
.each (error, data) ->
	data.split("\n").forEach (line) ->
		console.log line if line.match pattern
	@next()
.end()
