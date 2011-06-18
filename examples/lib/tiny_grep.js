(function() {
  var begin, def, files, fs, pattern, _ref;
  _ref = require('../..'), begin = _ref.begin, def = _ref.def;
  fs = require('fs');
  pattern = process.argv[2];
  files = process.argv.slice(3);
  console.log(pattern);
  console.log(files);
  begin(files).each(function(file) {
    return this._(function() {
      return fs.readFile(file, 'utf8', this.next);
    });
  }).each(function(error, data) {
    data.split("\n").forEach(function(line) {
      if (line.match(pattern)) {
        return console.log(line);
      }
    });
    return this.next();
  }).end();
}).call(this);
