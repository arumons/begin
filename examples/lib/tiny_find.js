(function() {
  var begin, def, dirname, find, fs, path, pattern, util, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _ref = require('../src/begin'), begin = _ref.begin, def = _ref.def;
  fs = require('fs');
  util = require('util');
  path = require('path');
  dirname = process.argv[2];
  pattern = process.argv[3];
  find = def(function(dirname) {
    return begin(function() {
      process.chdir(dirname);
      return fs.readdir('.', this.next);
    })._(function(error, files) {
      return this.next(files);
    }).each(function(file) {
      return fs.realpath(file, this.next);
    }).each(function(error, file) {
      return fs.stat(file, __bind(function(err, stat) {
        return this.next(err, stat, file);
      }, this));
    }).each(function(err, stat, file) {
      if ((path.basename(file)).match(pattern)) {
        console.log(path.basename(file));
      }
      if (stat.isDirectory()) {
        return find(file).end();
      } else {
        return this.next();
      }
    }).end();
  });
  find(".").end();
}).call(this);
