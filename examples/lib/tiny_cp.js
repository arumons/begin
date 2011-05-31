(function() {
  var begin, def, dist, fs, src, _ref;
  _ref = require('../src/begin'), begin = _ref.begin, def = _ref.def;
  fs = require('fs');
  src = process.argv[2];
  dist = process.argv[3];
  begin(function() {
    return fs.readFile(src, 'utf8', this.next);
  }).then(function(error, data) {
    return fs.writeFile(dist, data, this.next);
  }).end();
}).call(this);
