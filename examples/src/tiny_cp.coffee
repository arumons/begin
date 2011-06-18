{begin, def} = require '../..'
fs = require 'fs'

src = process.argv[2]
dist = process.argv[3]

begin ->
	@_ -> fs.readFile src, 'utf8', @next
._ (error, data) ->
	@_ -> fs.writeFile dist, data, @next
.end()
