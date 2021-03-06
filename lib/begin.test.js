(function() {
  var begin, def, macro, util;
  begin = require('..').begin;
  def = require('..').def;
  macro = require('..').macro;
  util = require('util');
  exports.begin_next_1 = function(test) {
    test.expect(1);
    return begin(function() {
      test.ok(true, "this assertion should pass");
      test.done();
      return this.next();
    }).end();
  };
  exports.begin_next_2 = function(test) {
    test.expect(2);
    return begin(function() {
      test.ok(true, "one");
      return this.next();
    })._(function() {
      test.ok(true, "two");
      test.done();
      return this.next();
    }).end();
  };
  exports.begin_next_3 = function(test) {
    test.expect(1);
    return begin(function() {
      return this.next(1);
    })._(function(v) {
      test.equal(v, 1);
      test.done();
      return this.next();
    }).end();
  };
  exports.begin_next_4 = function(test) {
    test.expect(2);
    return begin(function() {
      return this.next(1, 2);
    })._(function(v1, v2) {
      test.equal(v1, 1);
      test.equal(v2, 2);
      test.done();
      return this.next();
    }).end();
  };
  exports.begin_throw_1 = function(test) {
    test.expect(1);
    return begin(function() {
      return this["throw"]();
    })["catch"](function() {
      test.ok(true, 'catch success');
      test.done();
      return this.next();
    }).end();
  };
  exports.begin_throw_2 = function(test) {
    test.expect(2);
    return begin(function() {
      test.ok(true, 'one');
      return this["throw"]();
    })["catch"](function() {
      test.ok('true', 'two');
      test.done();
      return this.next();
    }).end();
  };
  exports.begin_throw_3 = function(test) {
    test.expect(1);
    return begin(function() {
      return this["throw"](1);
    })["catch"](function(v) {
      test.equal(v, 1);
      test.done();
      return this.next();
    }).end();
  };
  exports.begin_throw_4 = function(test) {
    test.expect(2);
    return begin(function() {
      return this["throw"](1, 2);
    })["catch"](function(v1, v2) {
      test.equal(v1, 1);
      test.equal(v2, 2);
      test.done();
      return this.next();
    }).end();
  };
  exports.next_and_throw_1 = function(test) {
    test.expect(2);
    return begin(function() {
      return this["throw"](1, 2);
    })._(function() {
      throw Error;
      return this.next;
    })._(function() {
      throw Error;
      return this["throw"];
    })["catch"](function(v1, v2) {
      test.equal(v1, 1);
      test.equal(v2, 2);
      test.done();
      return this.next();
    }).end();
  };
  exports.next_and_throw_2 = function(test) {
    test.expect(2);
    return begin(function() {
      return this.next(1, 2);
    })["catch"](function() {
      throw error;
      return this.next();
    })["catch"](function() {
      throw error;
      return this["throw"]();
    })._(function(v1, v2) {
      test.equal(v1, 1);
      test.equal(v2, 2);
      test.done();
      return this.next();
    }).end();
  };
  exports.real_throw_1 = function(test) {
    test.expect(2);
    return begin(function() {
      this.a = 10;
      throw "test";
    })["catch"](function(error) {
      test.equal(this.a, 10);
      test.equal(error, "test");
      test.done();
      return this.next();
    }).end();
  };
  exports.real_throw_2 = function(test) {
    test.expect(1);
    return begin(function() {
      this.a = 10;
      return this.next(10);
    })._(function(v) {
      test.equal(this.a, 10);
      throw "test";
    })["catch"](function(error) {
      test.done();
      return this.next();
    }).end();
  };
  exports.scope_1 = function(test) {
    test.expect(1);
    return begin(function() {
      this.a = 1;
      return this.next();
    })._(function() {
      test.equal(this.a, 1);
      test.done();
      return this.next();
    }).end();
  };
  exports.scope_2 = function(test) {
    test.expect(3);
    return begin(function() {
      this.a = 1;
      return this.next();
    })._(function() {
      test.equal(this.a, 1);
      this.b = 2;
      return this.next();
    })._(function() {
      test.equal(this.a, 1);
      test.equal(this.b, 2);
      test.done();
      return this.next();
    }).end();
  };
  exports.outer_1 = function(test) {
    test.expect(1);
    return begin(function() {
      return this._(function() {
        return begin(function() {
          return this.next(10);
        }).end();
      });
    })._(function(v) {
      test.equal(v, 10);
      test.done();
      return this.next();
    }).end();
  };
  exports.outer_2 = function(test) {
    test.expect(1);
    return begin(function() {
      return this._(function() {
        return begin(function() {
          return this["throw"](10);
        }).end();
      });
    })["catch"](function(v) {
      test.equal(v, 10);
      test.done();
      return this.next();
    }).end();
  };
  exports.use_outer_scope_1 = function(test) {
    test.expect(2);
    return begin(function() {
      this.a = 10;
      return this._(function() {
        return begin(function() {
          test.equal(this.a, 10);
          return this.next();
        }).end();
      });
    })._(function() {
      test.equal(this.a, 10);
      test.done();
      return this.next();
    }).end();
  };
  exports.use_outer_scope_2 = function(test) {
    test.expect(2);
    return begin(function() {
      this.a = 10;
      return this._(function() {
        return begin(function() {
          test.equal(this.a, 10);
          return this["throw"]();
        }).end();
      });
    })["catch"](function() {
      test.equal(this.a, 10);
      test.done();
      return this.next();
    }).end();
  };
  exports.use_outer_scope_3 = function(test) {
    test.expect(2);
    return begin(function() {
      this.a = 10;
      return this._(function() {
        return begin(function() {
          test.equal(this.a, 10);
          return this.out();
        }).end();
      });
    })._(function() {
      test.equal(this.a, 10);
      test.done();
      return this.next();
    }).end();
  };
  exports.def_1 = function(test) {
    var t;
    t = def(function() {
      return this.next(1);
    }).end();
    return begin(function() {
      return this._(function() {
        return t();
      });
    })._(function(v) {
      test.equal(v, 1);
      test.done();
      return this.next();
    }).end();
  };
  exports.def_2 = function(test) {
    var t;
    test.expect(1);
    t = def(function(v) {
      return this.next(v * 3);
    }).end();
    return begin(function() {
      return this._(function() {
        return t(3);
      });
    })._(function(v) {
      test.equal(v, 9);
      test.done();
      return this.next();
    }).end();
  };
  exports.def_3 = function(test) {
    var t;
    test.expect(1);
    t = def(function(v) {
      this.test = v;
      return this.next();
    }).end();
    return begin(function() {
      return this._(function() {
        return t(10);
      });
    })._(function() {
      test.equal(void 0, this.test);
      test.done();
      return this.next();
    }).end();
  };
  exports.def_4 = function(test) {
    var t, t2;
    test.expect(1);
    t = def(function(v) {
      return this.next(v * 3);
    }).end();
    t2 = def(function(v) {
      return this._(function() {
        return t(v);
      });
    }).end();
    return begin(function() {
      return this._(function() {
        return t2(5);
      });
    })._(function(v) {
      test.equal(v, 15);
      test.done();
      return this.next();
    }).end();
  };
  exports.out_1 = function(test) {
    test.expect(2);
    return begin(function() {
      return this._(function() {
        return begin(function() {
          this.a = 10;
          return this.out();
        })._(function() {
          test.ok(true, 'not come');
          return this["throw"]();
        })["catch"](function() {
          test.ok(true, 'not come');
          return this.next();
        }).end();
      });
    })._(function() {
      test.ok(true, 'only come');
      test.equal(this.a, 10);
      test.done();
      return this.next();
    }).end();
  };
  exports.def_with_receiver_1 = function(test) {
    var obj;
    test.expect(3);
    obj = {
      a: 1,
      b: 2
    };
    obj.t = def(function(v) {
      test.equal(v, 10);
      test.equal(this.self.a, 1);
      test.equal(this.self.b, 2);
      test.done();
      return this.next();
    }).end();
    return obj.t(10);
  };
  exports.filter_1 = function(test) {
    test.expect(2);
    return begin(function() {
      return this.filter([1, 2, 3], function(v) {
        this.a = 10;
        return this.next(v % 2 === 0);
      });
    })._(function(lst) {
      test.equal(this.a, 10);
      test.deepEqual(lst, [2]);
      test.done();
      return this.next();
    }).end();
  };
  exports.filter_2 = function(test) {
    test.expect(1);
    return begin(function() {
      return this.filter([1], function(v) {
        this.test = 30;
        return this.next(true);
      });
    })._(function(lst) {
      test.equal(this.test, 30);
      test.done();
      return this.next();
    }).end();
  };
  exports.filter_3 = function(test) {
    var a;
    test.expect(2);
    a = def(function(v) {
      this.test = 30;
      return this.next(true);
    }).end();
    return begin(function() {
      return this.filter([5], a);
    })._(function(lst) {
      test.equal(this.test, void 0);
      test.deepEqual(lst, [5]);
      test.done();
      return this.next();
    }).end();
  };
  exports.filter_4 = function(test) {
    test.expect(1);
    return begin(function() {
      return this.filter([1], function(v) {
        return this["throw"](true);
      });
    })._(function(v) {
      test.done();
      return this.next(false);
    })["catch"](function(v) {
      test.ok(v, 'catched');
      test.done();
      return this.next();
    }).end();
  };
  exports.filter_5 = function(test) {
    test.expect(2);
    return begin(function() {
      return this._(function() {
        return begin(function() {
          return this.filter([1, 2], function(v) {
            return this.out(true);
          });
        })._(function(v) {
          test.deepEqual(v, [1, 2]);
          return this.next(true);
        })["catch"](function(v) {
          return this.next(false);
        }).end();
      });
    })._(function(v) {
      test.ok(v, 'catched');
      test.done();
      return this.next();
    }).end();
  };
  exports.map_1 = function(test) {
    test.expect(2);
    return begin(function() {
      return this.map([1, 2, 3], function(v) {
        this.a = 10;
        return this.next(v * 2);
      });
    })._(function(lst) {
      test.equal(this.a, 10);
      test.deepEqual(lst, [2, 4, 6]);
      test.done();
      return this.next();
    }).end();
  };
  exports.map_2 = function(test) {
    test.expect(2);
    return begin(function() {
      return this.map([1, 2, 3], function(v) {
        this.a = 10;
        return this.next(v * 2);
      });
    })._(function(lst) {
      test.equal(this.a, 10);
      test.deepEqual(lst, [2, 4, 6]);
      test.done();
      return this.next();
    }).end();
  };
  exports.map_3 = function(test) {
    var a;
    test.expect(1);
    a = def(function(v) {
      return this.next(v * v);
    }).end();
    return begin(function() {
      return this.map([1, 2, 3], a);
    })._(function(lst) {
      test.deepEqual(lst, [1, 4, 9]);
      test.done();
      return this.next();
    }).end();
  };
  exports.every_1 = function(test) {
    test.expect(1);
    return begin(function() {
      return this.every([1, 2, 3], function(v) {
        return this.next(v < 5);
      });
    })._(function(v) {
      test.equal(true, v);
      test.done();
      return this.next();
    }).end();
  };
  exports.every_2 = function(test) {
    test.expect(2);
    return begin(function() {
      return this.every([1, 2, 3], function(v) {
        this.a = 10;
        return this.next(v < 2);
      });
    })._(function(v) {
      test.equal(this.a, 10);
      test.equal(v, false);
      test.done();
      return this.next();
    }).end();
  };
  exports.every_3 = function(test) {
    var a;
    test.expect(1);
    a = def(function(v) {
      return this.next(v > 0);
    }).end();
    return begin(function() {
      return this.every([1, 2, 3], a);
    })._(function(v) {
      test.equal(v, true);
      test.done();
      return this.next();
    }).end();
  };
  exports.some_1 = function(test) {
    test.expect(1);
    return begin(function() {
      return this.some([1, 2, 3], function(v) {
        return this.next(v === 2);
      });
    })._(function(v) {
      test.equal(true, v);
      test.done();
      return this.next();
    }).end();
  };
  exports.some_2 = function(test) {
    test.expect(2);
    return begin(function() {
      return this.some([1, 2, 3], function(v) {
        this.a = 10;
        return this.next(v > 4);
      });
    })._(function(v) {
      test.equal(this.a, 10);
      test.equal(v, false);
      test.done();
      return this.next();
    }).end();
  };
  exports.some_3 = function(test) {
    var a;
    test.expect(1);
    a = def(function(v) {
      return this.next(v > 2);
    }).end();
    return begin(function() {
      return this.some([1, 2, 3], a);
    })._(function(v) {
      test.equal(v, true);
      test.done();
      return this.next();
    }).end();
  };
  exports.reduce_1 = function(test) {
    test.expect(1);
    return begin(function() {
      return this.reduce([1, 2, 3], function(pv, cv) {
        return this.next(pv * cv);
      });
    })._(function(v) {
      test.equal(v, 6);
      test.done();
      return this.next();
    }).end();
  };
  exports.reduce_2 = function(test) {
    test.expect(2);
    return begin(function() {
      return this.reduce([1, 2, 3], function(pv, cv) {
        this.a = 20;
        return this.next(pv * cv);
      });
    })._(function(v) {
      test.equal(this.a, 20);
      test.equal(v, 6);
      test.done();
      return this.next();
    }).end();
  };
  exports.reduce_3 = function(test) {
    var f;
    test.expect(2);
    f = def(function(pv, cv) {
      this.a = 10;
      return this.next(pv * cv);
    }).end();
    return begin(function() {
      return this.reduce([1, 2, 3], f);
    })._(function(v) {
      test.equal(this.a, void 0);
      test.equal(v, 6);
      test.done();
      return this.next();
    }).end();
  };
  exports.reduceRight_1 = function(test) {
    test.expect(1);
    return begin(function() {
      return this.reduceRight([1, 2, 3], function(pv, cv) {
        return this.next(pv - cv);
      });
    })._(function(v) {
      test.equal(v, 0);
      test.done();
      return this.next();
    }).end();
  };
  exports.reduceRight_4 = function(test) {
    test.expect(2);
    return begin(function() {
      return this.reduceRight([1, 2, 3], function(pv, cv) {
        this.a = 10;
        return this.next(pv - cv);
      });
    })._(function(v) {
      test.equal(v, 0);
      test.equal(this.a, 10);
      test.done();
      return this.next();
    }).end();
  };
}).call(this);
