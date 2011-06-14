{begin, def} = require '../..'
fs = require 'fs'
path = require 'path'

dirname = process.argv[2]
pattern = process.argv[3]

find =
    def (dirname) ->
		process.chdir(dirname)
		fs.readdir '.', @next
	._ (error, files) ->
		@next files
	.each (file) ->
		fs.realpath file, @next
	.each (error, file) ->
		fs.stat file, (err, stat) => @next err, stat, file
	.each (err, stat, file) ->
		if (path.basename file).match pattern
			console.log path.basename file
		if stat.isDirectory()
			find(file)
		else
			@next()
	.end()

find(".")
	
