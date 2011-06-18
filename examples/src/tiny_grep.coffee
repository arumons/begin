{begin, def} = require '../..'
fs = require 'fs'

pattern = process.argv[2]
files = process.argv[3..]

console.log pattern
console.log files

begin(files).each (file) ->
	@_ -> fs.readFile file, 'utf8', @next
.each (error, data) ->
	data.split("\n").forEach (line) ->
		console.log line if line.match pattern
	@next()
.end()
