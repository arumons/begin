{begin, def} = require '../..'
fs = require 'fs'
path = require 'path'

dirname = process.argv[2]
pattern = process.argv[3]

find =
    def (dirname) ->
		process.chdir(dirname)
		@_ -> fs.readdir '.', @next
	._ (error, files) ->
		@next files
	.each (file) ->
		@_ -> fs.realpath file, @next
	.each (error, file) ->
		@_ -> fs.stat file, (err, stat) => @next err, stat, file
	.each (err, stat, file) ->
		if (path.basename file).match pattern
			console.log path.basename file
		if stat.isDirectory()
			@_ -> find(file)
		else
			@next()
	.end()

find(".")
	
