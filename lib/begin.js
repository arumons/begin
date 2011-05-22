(function() {
  var ArrayUnits, Scope, Unit, Units, begin, def, events, macro, util;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  events = require('events');
  util = require('util');
  Scope = (function() {
    function Scope(unit, self) {
      this.unit = unit;
      this.self = self;
    }
    Scope.prototype.next = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      args.unshift('next');
      return this.unit.emit.apply(this.unit, args);
    };
    Scope.prototype["throw"] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      args.unshift('throw');
      return this.unit.emit.apply(this.unit, args);
    };
    Scope.prototype["return"] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      args.unshift('return');
      return this.unit.emit.apply(this.unit, args);
    };
    return Scope;
  })();
  Unit = (function() {
    __extends(Unit, events.EventEmitter);
    function Unit(block, receiver, succeed) {
      this.block = block;
      this.succeed = succeed;
      this.is_unit = true;
      this.scope = Object.create(new Scope(this, receiver));
      events.EventEmitter.call(this);
    }
    Unit.prototype.end = function(succeed) {
      var continuation;
      continuation = Units.CurrentContinuation;
      this.on('next', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (succeed && (continuation != null)) {
          this._shift(this.scope, continuation);
        }
        if (continuation != null) {
          return continuation.next.apply(continuation, args);
        } else {
          return Units.CurrentContinuation = void 0;
        }
      });
      this.on('throw', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (succeed && (continuation != null)) {
          this._shift(this.scope, continuation);
        }
        if (continuation != null) {
          return continuation["throw"].apply(continuation, args);
        } else {
          return Units.CurrentContinuation = void 0;
        }
      });
      return this.on('return', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (succeed && (continuation != null)) {
          this._shift(this.scope, continuation);
        }
        if (continuation != null) {
          return continuation.next.apply(continuation, args);
        } else {
          return Units.CurrentContinuation = void 0;
        }
      });
    };
    Unit.prototype.then = function(unit) {
      this.on('next', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._next_scope(unit, args);
      });
      this.on('throw', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._skip_scope(unit, 'throw', args);
      });
      this.on('return', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._skip_scope(unit, 'return', args);
      });
      this.next_unit = unit;
      unit.previous_unit = this;
      return unit;
    };
    Unit.prototype["catch"] = function(unit) {
      this.on('next', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._skip_scope(unit, 'next', args);
      });
      this.on('throw', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._next_scope(unit, args);
      });
      this.on('return', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._skip_scope(unit, 'return', args);
      });
      this.next_unit = unit;
      unit.previous_unit = this;
      return unit;
    };
    Unit.prototype.invoke = function() {
      if (this.previous_unit != null) {
        return this.previous_unit.invoke();
      } else {
        if ((this.succeed != null) && (Units.CurrentContinuation != null)) {
          this._succeed(Units.CurrentContinuation);
        }
        Units.CurrentContinuation = this.scope;
        try {
          return this.block.call(this.scope);
        } catch (error) {
          return this._skip_scope(this, 'throw', [error]);
        }
      }
    };
    Unit.prototype._succeed = function(outer_scope) {
      var key, _results;
      _results = [];
      for (key in outer_scope) {
        if (!__hasProp.call(outer_scope, key)) continue;
        _results.push(this._set_property(key, outer_scope));
      }
      return _results;
    };
    Unit.prototype._set_property = function(name, outer_scope) {
      return Object.defineProperty(this.scope, name, {
        get: function() {
          return outer_scope[name];
        },
        set: function(v) {
          return outer_scope[name] = v;
        }
      });
    };
    Unit.prototype._next_scope = function(next_unit, args) {
      this._shift(this.scope, next_unit.scope);
      Units.CurrentContinuation = next_unit.scope;
      try {
        return next_unit.block.apply(next_unit.scope, args);
      } catch (error) {
        return this._skip_scope(next_unit, 'throw', [error]);
      }
    };
    Unit.prototype._skip_scope = function(next_unit, event, args) {
      this._shift(this.scope, next_unit.scope);
      Units.CurrentContinuation = next_unit.scope;
      args.unshift(event);
      return next_unit.emit.apply(next_unit, args);
    };
    Unit.prototype._shift = function(a, b) {
      var key, _results;
      _results = [];
      for (key in a) {
        if (!__hasProp.call(a, key)) continue;
        _results.push(b[key] = a[key]);
      }
      return _results;
    };
    return Unit;
  })();
  ArrayUnits = (function() {
    function ArrayUnits() {}
    ArrayUnits.prototype._prepare = function(block, thisp) {
      var defed;
      if (!(thisp != null)) {
        thisp = global;
      }
      if (block.is_defed) {
        defed = block;
      } else {
        defed = macro(block);
      }
      return {
        defed: defed,
        thisp: thisp,
        units: new Units(function() {
          return this.next();
        })
      };
    };
    ArrayUnits.prototype.filter = function(block, thisp) {
      var defed, result, units, _ref;
      _ref = this._prepare(block, thisp), defed = _ref.defed, thisp = _ref.thisp, units = _ref.units;
      result = [];
      return new Units(function(array) {
        array.forEach(function(item, index, array) {
          return units.then(defed.call(thisp, item, index, array)).then(function(v) {
            if (v) {
              result.push(item);
            }
            return this.next();
          });
        });
        units.then(function() {
          return this.next(result);
        });
        return units.end(true);
      });
    };
    ArrayUnits.prototype.each = function(block, thisp) {
      var defed, result, units, _ref;
      _ref = this._prepare(block, thisp), defed = _ref.defed, thisp = _ref.thisp, units = _ref.units;
      result = [];
      return new Units(function(array) {
        array.forEach(function(item, index, array) {
          return units.then(defed.call(thisp, item, index, array)).then(function(v) {
            result.push(v);
            return this.next();
          });
        });
        units.then(function() {
          return this.next(result);
        });
        return units.end(true);
      });
    };
    ArrayUnits.prototype.every = function(block, thisp) {
      var defed, units, _ref;
      _ref = this._prepare(block, thisp), defed = _ref.defed, thisp = _ref.thisp, units = _ref.units;
      return new Units(function(array) {
        units = new Units(function() {
          return this.next();
        });
        array.forEach(function(item, index, array) {
          return units.then(defed.call(thisp, item, index, array)).then(function(v) {
            if (!v) {
              return this["return"](false);
            } else {
              return this.next();
            }
          });
        });
        return units.then(function() {
          return this["return"](true);
        }).end(true);
      });
    };
    ArrayUnits.prototype.some = function(block, thisp) {
      var defed, unit, _ref;
      _ref = this._prepare(block, thisp), defed = _ref.defed, thisp = _ref.thisp, unit = _ref.unit;
      return new Units(function(array) {
        var units;
        units = new Units(function() {
          return this.next();
        });
        array.forEach(function(item, index, array) {
          return units.then(defed.call(thisp, item, index, array)).then(function(v) {
            if (v) {
              return this["return"](true);
            } else {
              return this.next();
            }
          });
        });
        return units.then(function() {
          return this["return"](false);
        }).end(true);
      });
    };
    ArrayUnits.prototype.reduce = function(block, init, reverse) {
      return new Units(function(array) {
        var i, units, _array;
        i = 0;
        units = new Units(function() {
          if (array.length === 0) {
            return this["throw"](new TypeError());
          } else {
            return this.next();
          }
        });
        if (reverse) {
          array = array.reverse();
        }
        if (init != null) {
          units.then(function() {
            return this.next(init, array[0], i++, array);
          });
          _array = array.slice(1);
        } else {
          i++;
          units.then(function() {
            return this.next(array[0], array[1], i++, array);
          });
          _array = array.slice(2);
        }
        _array.forEach(function(item) {
          return units.then(block).then(function(v) {
            return this.next(v, item, i++, array);
          });
        });
        units.then(block);
        return units.then(function(result) {
          return this.next(result);
        }).end(true);
      });
    };
    ArrayUnits.prototype.reduceRight = function(block, init) {
      return this.reduce(block, init, true);
    };
    return ArrayUnits;
  })();
  Units = (function() {
    function Units(block, context, succeed) {
      this.head = new Unit(block, context, succeed);
      this.tail = this.head;
      this.is_units = true;
    }
    Units.prototype.then = function(block, context) {
      var units;
      if (block.is_unit) {
        this.tail = this.tail.then(block);
      } else if (block.is_units) {
        this.tail.then(block.head);
        this.tail = block.tail;
      } else if (block.is_defed || block.is_macro) {
        units = block();
        this.tail = this.tail.then(units.head);
        this.tail = units.tail;
      } else if (Array.isArray(block)) {
        this.tail = this.tail.then(new Unit(function() {
          return this.next(block);
        }));
      } else {
        this.tail = this.tail.then(new Unit(block, context));
      }
      return this;
    };
    Units.prototype["catch"] = function(block, context) {
      var units;
      if (block.is_unit) {
        this.tail = this.tail["catch"](block);
      } else if (block.is_units) {
        this.tail["catch"](block.head);
        this.tail = block.tail;
      } else if (block.is_defed) {
        units = block();
        this.tail = this.tail["catch"](units.head);
        this.tail = units.tail;
      } else if (Array.isArray(block)) {
        this.tail = this.tail["catch"](new Unit(function() {
          return this.next(block);
        }));
      } else {
        this.tail = this.tail["catch"](new Unit(block, context));
      }
      return this;
    };
    Units.prototype.end = function(succeed) {
      this.tail.end(succeed);
      return this.tail.invoke();
    };
    Units.prototype.filter = function(block, thisp) {
      return this.then(new ArrayUnits().filter(block, thisp));
    };
    Units.prototype.each = function(block, thisp) {
      return this.then(new ArrayUnits().each(block, thisp));
    };
    Units.prototype.every = function(block, thisp) {
      return this.then(new ArrayUnits().every(block, thisp));
    };
    Units.prototype.some = function(block, thisp) {
      return this.then(new ArrayUnits().some(block, thisp));
    };
    Units.prototype.reduce = function(block, init) {
      return this.then(new ArrayUnits().reduce(block, init));
    };
    Units.prototype.reduceRight = function(block, init) {
      return this.then(new ArrayUnits().reduceRight(block, init));
    };
    return Units;
  })();
  begin = function(block) {
    if (Array.isArray(block)) {
      return new Units((function() {
        return this.next(block);
      }), void 0, true);
    } else {
      return new Units(block, void 0, true);
    }
  };
  macro = function(block) {
    var defed;
    defed = function() {
      var args, units;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (args.length === 0) {
        args = [];
      }
      units = new Units((function() {
        return this.next.apply(this, args);
      }));
      return units.then(block, this);
    };
    defed.is_macro = true;
    return defed;
  };
  def = function(block) {
    var defed;
    defed = function() {
      var args, self, units;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (args.length === 0) {
        args = [];
      }
      self = this;
      return units = new Units(function() {
        return begin(function() {
          return this.next.apply(this, args);
        }).then(block, self).end();
      });
    };
    defed.is_defed = true;
    return defed;
  };
  exports.begin = begin;
  exports.def = def;
}).call(this);
