(function() {
  var ArrayUnits, Arrays, Def, Scope, Unit, Units, arrays, begin, def, macro;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty;
  Scope = (function() {
    function Scope(unit) {
      var jumped, _err_msg, _pre_scope_transition_function;
      jumped = false;
      _err_msg = "you can call scope transition function only once in a scope";
      _pre_scope_transition_function = function() {
        if (jumped) {
          throw new Error(_err_msg);
        }
        return jumped = true;
      };
      this["throw"] = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _pre_scope_transition_function();
        unit["throw"].apply(unit, args);
        return unit;
      };
      this.out = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _pre_scope_transition_function();
        unit.out.apply(unit, args);
        return unit;
      };
      this.next = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _pre_scope_transition_function();
        unit.next.apply(unit, args);
        return unit;
      };
      this._ = function(block) {
        var self;
        self = this;
        block.call(self);
        return unit;
      };
    }
    return Scope;
  })();
  Unit = (function() {
    function Unit(block, receiver, use_outer_scope) {
      this.block = block;
      if (receiver == null) {
        receiver = void 0;
      }
      this.use_outer_scope = use_outer_scope != null ? use_outer_scope : true;
      this.scope = Object.create(new Scope(this));
      this.scope.self = receiver;
    }
    Unit.prototype.end = function() {
      var continuation;
      continuation = Units.CurrentContinuation;
      this.next = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (this.use_outer_scope && (continuation != null)) {
          this._shift(this.scope, continuation);
        }
        if (continuation != null) {
          continuation.next.apply(continuation, args);
          return;
        }
        return Units.CurrentContinuation = void 0;
      };
      this["throw"] = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (this.use_outer_scope && (continuation != null)) {
          this._shift(this.scope, continuation);
        }
        if (continuation != null) {
          continuation["throw"].apply(continuation, args);
          return;
        }
        Units.CurrentContinuation = void 0;
        return process.nextTick(function() {
          throw args[0];
        });
      };
      return this.out = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (this.use_outer_scope && (continuation != null)) {
          this._shift(this.scope, continuation);
        }
        if (continuation != null) {
          continuation.next.apply(continuation, args);
          return;
        }
        return Units.CurrentContinuation = void 0;
      };
    };
    Unit.prototype._ = function(unit) {
      this.next = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._next_scope(unit, args);
      };
      this["throw"] = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._skip_scope(unit, 'throw', args);
      };
      this.out = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._skip_scope(unit, 'out', args);
      };
      this.next_unit = unit;
      unit.previous_unit = this;
      return unit;
    };
    Unit.prototype["catch"] = function(unit) {
      this.next = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._skip_scope(unit, 'next', args);
      };
      this["throw"] = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._next_scope(unit, args);
      };
      this.out = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this._skip_scope(unit, 'out', args);
      };
      this.next_unit = unit;
      unit.previous_unit = this;
      return unit;
    };
    Unit.prototype.invoke = function() {
      if (this.previous_unit != null) {
        this.previous_unit.invoke();
        return;
      }
      if (this.use_outer_scope && (Units.CurrentContinuation != null)) {
        this._shift(Units.CurrentContinuation, this.scope);
      }
      return this._next_scope(this, []);
    };
    Unit.prototype._next_scope = function(next_unit, args) {
      if (this !== next_unit) {
        next_unit.use_outer_scope = this.use_outer_scope;
        this._shift(this.scope, next_unit.scope);
      }
      Units.CurrentContinuation = next_unit.scope;
      try {
        if (next_unit !== next_unit.block.apply(next_unit.scope, args)) {
          throw new Error("you must call scope trasition function at end of scope.");
        }
        return Units.CurrentContinuation = void 0;
      } catch (error) {
        return this._skip_scope(next_unit, 'throw', [error]);
      }
    };
    Unit.prototype._skip_scope = function(next_unit, event, args) {
      next_unit.use_outer_scope = this.use_outer_scope;
      this._shift(this.scope, next_unit.scope);
      Units.CurrentContinuation = next_unit.scope;
      return next_unit[event].apply(next_unit, args);
    };
    Unit.prototype._shift = function(from, to) {
      var p, _results;
      _results = [];
      for (p in from) {
        if (!__hasProp.call(from, p)) continue;
        _results.push(to[p] = from[p]);
      }
      return _results;
    };
    return Unit;
  })();
  arrays = function() {
    var arrays;
    arrays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return new Arrays(arrays);
  };
  Arrays = (function() {
    function Arrays(arrays) {
      this.ziped = Arrays.zip(arrays);
    }
    Arrays.zip = function(arrays) {
      var i, line, max;
      max = 0;
      arrays.forEach(function(array) {
        var len;
        len = array.length;
        if (max < len) {
          return max = len;
        }
      });
      line = [];
      for (i = 0; 0 <= max ? i < max : i > max; 0 <= max ? i++ : i--) {
        line.push(arrays.map(function(v) {
          return v["" + i];
        }));
      }
      return line;
    };
    Arrays.prototype.each = function(block, thisp) {
      var result;
      result = [];
      if (!(thisp != null)) {
        thisp = global;
      }
      this.ziped.map(function(args, i, _array) {
        args.push(i);
        args.push(_array);
        return result.push(block.apply(thisp, args));
      });
      return result;
    };
    return Arrays;
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
        defed = macro(block).end();
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
      return new Units(function() {
        var _arrays;
        _arrays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        arrays.apply(null, _arrays).each(function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          units._((function() {
            return this._(function() {
              return defed.apply(thisp, args);
            });
          }));
          return units._(function(v) {
            if (v) {
              result.push(args.slice(0, -2));
            }
            return this.next();
          });
        });
        units._(function() {
          return this.next.apply(this, Arrays.zip(result));
        });
        return this._(function() {
          return units.end();
        });
      });
    };
    ArrayUnits.prototype.each = function(block, thisp) {
      var defed, result, units, _ref;
      _ref = this._prepare(block, thisp), defed = _ref.defed, thisp = _ref.thisp, units = _ref.units;
      result = [];
      return new Units(function() {
        var _arrays;
        _arrays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        arrays.apply(null, _arrays).each(function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          units._((function() {
            return this._(function() {
              return defed.apply(thisp, args);
            });
          }));
          return units._(function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            result.push(args);
            return this.next();
          });
        });
        units._(function() {
          return this.next.apply(this, Arrays.zip(result));
        });
        return this._(function() {
          return units.end();
        });
      });
    };
    ArrayUnits.prototype.every = function(block, thisp) {
      var defed, units, _ref;
      _ref = this._prepare(block, thisp), defed = _ref.defed, thisp = _ref.thisp, units = _ref.units;
      return new Units(function(array) {
        array.forEach(function(item, index, array) {
          return units._((function() {
            return this._(function() {
              return defed.call(thisp, item, index, array);
            });
          }))._(function(v) {
            if (!v) {
              return this.out(false);
            } else {
              return this.next();
            }
          });
        });
        return this._(function() {
          return units._(function() {
            return this.out(true);
          }).end();
        });
      });
    };
    ArrayUnits.prototype.some = function(block, thisp) {
      var defed, units, _ref;
      _ref = this._prepare(block, thisp), defed = _ref.defed, thisp = _ref.thisp, units = _ref.units;
      return new Units(function(array) {
        array.forEach(function(item, index, array) {
          return units._((function() {
            return this._(function() {
              return defed.call(thisp, item, index, array);
            });
          }))._(function(v) {
            if (v) {
              return this.out(true);
            } else {
              return this.next();
            }
          });
        });
        return this._(function() {
          return units._(function() {
            return this.out(false);
          }).end();
        });
      });
    };
    ArrayUnits.prototype.reduce = function(block, init, reverse) {
      var defed, global;
      global = (function() {
        return this;
      })();
      defed;
      if (block.is_defed) {
        defed = block;
      } else {
        defed = macro(block).end();
      }
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
          units._(function() {
            return this.next(init, array[0], i++, array);
          });
          _array = array.slice(1);
        } else {
          i++;
          units._(function() {
            return this.next(array[0], array[1], i++, array);
          });
          _array = array.slice(2);
        }
        _array.forEach(function(item) {
          return units._(function(v1, v2, i, array) {
            return this._(function() {
              return defed.call(global, v1, v2, i, array);
            });
          })._(function(v) {
            return this.next(v, item, i++, array);
          });
        });
        units._(function(v1, v2, i, array) {
          return this._(function() {
            return defed.call(global, v1, v2, i, array);
          });
        });
        return this._(function() {
          return units._(function(result) {
            return this.next(result);
          }).end();
        });
      });
    };
    ArrayUnits.prototype.reduceRight = function(block, init) {
      return this.reduce(block, init, true);
    };
    return ArrayUnits;
  })();
  Units = (function() {
    var p, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3;
    function Units(block, context, use_outer_scope) {
      if (context == null) {
        context = void 0;
      }
      if (use_outer_scope == null) {
        use_outer_scope = true;
      }
      this.head = new Unit(block, context, use_outer_scope);
      this.tail = this.head;
    }
    _ref = ['_', 'catch'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      p = _ref[_i];
      Units.prototype[p] = (function(p) {
        return function(block) {
          if (block instanceof Unit) {
            this.tail = this.tail[p](block);
          } else if (block instanceof Units) {
            this.tail[p](block.head);
            this.tail = block.tail;
          } else if (Array.isArray(block)) {
            this.tail = this.tail[p](new Unit(function() {
              return this.next(block);
            }));
          } else {
            this.tail = this.tail[p](new Unit(block));
          }
          return this;
        };
      })(p);
    }
    _ref2 = ['filter', 'each', 'every', 'some'];
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      p = _ref2[_j];
      Units.prototype[p] = (function(p) {
        return function(block, thisp) {
          return this._(new ArrayUnits()[p](block, thisp));
        };
      })(p);
    }
    _ref3 = ['reduce', 'reduceRight'];
    for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
      p = _ref3[_k];
      Units.prototype[p] = (function(p) {
        return function(block, init) {
          return this._(new ArrayUnits()[p](block, init));
        };
      })(p);
    }
    Units.prototype.end = function() {
      this.tail.end();
      return this.tail.invoke();
    };
    return Units;
  })();
  Def = (function() {
    var p, _i, _j, _len, _len2, _ref, _ref2;
    function Def(block, use_outer_scope) {
      this.use_outer_scope = use_outer_scope != null ? use_outer_scope : false;
      this.factory = function() {
        return new Units(block);
      };
    }
    _ref = ['_', 'catch', 'each', 'filter', 'every', 'some'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      p = _ref[_i];
      Def.prototype[p] = (function(p) {
        return function(block) {
          var previous_factory;
          previous_factory = this.factory;
          this.factory = function() {
            return previous_factory()[p](block);
          };
          return this;
        };
      })(p);
    }
    _ref2 = ['reduce', 'reduceRight'];
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      p = _ref2[_j];
      Def.prototype[p] = (function(p) {
        return function(block, init) {
          var previous_factory;
          previous_factory = this.factory;
          this.factory = function() {
            return previous_factory()[p](block, init);
          };
          return this;
        };
      })(p);
    }
    Def.prototype.end = function() {
      var defed, factory, use_outer_scope;
      factory = this.factory;
      use_outer_scope = this.use_outer_scope;
      defed = function() {
        var args, self;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        self = this;
        return begin((function() {
          return this.next.apply(this, args);
        }), self, use_outer_scope)._(factory()).end();
      };
      defed.is_defed = true;
      return defed;
    };
    return Def;
  })();
  begin = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    if (Array.isArray(args[0])) {
      return new Units((function() {
        return this.next.apply(this, args);
      }), void 0, true);
    } else {
      return new Units(args[0], args[1], args[2]);
    }
  };
  def = function(block) {
    return new Def(block);
  };
  macro = function(block) {
    return new Def(block, true);
  };
  exports.begin = begin;
  exports.def = def;
  exports.macro = macro;
}).call(this);
