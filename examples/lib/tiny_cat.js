var begin, def, files, fs, _ref;
_ref = require('../src/begin'), begin = _ref.begin, def = _ref.def;
fs = require('fs');
files = process.argv.slice(2);
begin(files).each(function(file) {
  return fs.readFile(file, 'utf8', this.next);
}).each(function(error, data) {
  process.stdout.write(data);
  return this.next();
}).end();