{begin, def} = require '../src/begin'
fs = require 'fs'

src = process.argv[2]
dist = process.argv[3]

begin ->
	fs.readFile src, 'utf8', @next
.then (error, data) ->
	fs.writeFile dist, data, @next
.end()
