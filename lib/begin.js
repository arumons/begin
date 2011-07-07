(function() {
  var Arrays, Def, Scope, Unit, Units, arrays, begin, def, macro;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty;
  Scope = (function() {
    function Scope(unit) {
      var jumped, _err_msg, _pre_iterator_function;
      jumped = false;
      _err_msg = "you can call scope transition function only once in a scope";
      _pre_iterator_function = function(args) {
        var arg, fn, thisp, _arrays, _ref;
        _arrays = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = args.length; _i < _len; _i++) {
            arg = args[_i];
            if (Array.isArray(arg)) {
              _results.push(arg);
            }
          }
          return _results;
        })();
        fn = args[_arrays.length];
        thisp = (_ref = args[_arrays.length + 1]) != null ? _ref : global;
        return {
          _arrays: _arrays,
          defed: fn.is_defed ? fn : macro(fn).end(),
          thisp: thisp,
          units: new Units((function() {
            return this.next();
          }), thisp, true)
        };
      };
      this["throw"] = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        unit["throw"].apply(unit, args);
        return unit;
      };
      this.out = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        unit.out.apply(unit, args);
        return unit;
      };
      this.next = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        unit.next.apply(unit, args);
        return unit;
      };
      this._ = function(block) {
        var self;
        self = this;
        block.call(self);
        return unit;
      };
      this.filter = function() {
        var args, defed, result, thisp, units, _arrays, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _ref = _pre_iterator_function(args), _arrays = _ref._arrays, defed = _ref.defed, thisp = _ref.thisp, units = _ref.units;
        result = [];
        arrays.apply(null, _arrays).map(function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          units._(function() {
            return this._(function() {
              return defed.apply(thisp, args);
            });
          });
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
        units.end();
        return unit;
      };
      this.map = function() {
        var args, defed, result, thisp, units, _arrays, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _ref = _pre_iterator_function(args), _arrays = _ref._arrays, defed = _ref.defed, thisp = _ref.thisp, units = _ref.units;
        result = [];
        arrays.apply(null, _arrays).map(function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          units._(function() {
            return this._(function() {
              return defed.apply(thisp, args);
            });
          });
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
        units.end();
        return unit;
      };
      this.every = function() {
        var args, defed, thisp, units, _arrays, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _ref = _pre_iterator_function(args), _arrays = _ref._arrays, defed = _ref.defed, thisp = _ref.thisp, units = _ref.units;
        arrays.apply(null, _arrays).map(function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          units._(function() {
            return this._(function() {
              return defed.apply(thisp, args);
            });
          });
          return units._(function(v) {
            if (!v) {
              return this.out(false);
            } else {
              return this.next();
            }
          });
        });
        units._(function() {
          return this.out(true);
        });
        units.end();
        return unit;
      };
      this.some = function() {
        var args, defed, thisp, units, _arrays, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _ref = _pre_iterator_function(args), _arrays = _ref._arrays, defed = _ref.defed, thisp = _ref.thisp, units = _ref.units;
        arrays.apply(null, _arrays).map(function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          units._(function() {
            return this._(function() {
              return defed.apply(thisp, args);
            });
          });
          return units._(function(v) {
            if (v) {
              return this.out(true);
            } else {
              return this.next();
            }
          });
        });
        units._(function() {
          return this.out(false);
        });
        units.end();
        return unit;
      };
      this.reduce = function(array, block, init, reverse) {
        var defed, global, i, units, _array;
        global = (function() {
          return this;
        })();
        defed = block.is_defed ? block : macro(block).end();
        i = 0;
        units = new Units(function() {
          if (array.length <= 0) {
            throw new TypeError();
          }
          return this.next();
        });
        if (reverse) {
          array = array.reverse();
        }
        if (init != null) {
          units._(this.next(init, array[0], i++, array));
          _array = array.slice(1);
        } else {
          i++;
          units._(function() {
            return this.next(array[0], array[1], i++, array);
          });
          _array = array.slice(2);
        }
        _array.forEach(function(item) {
          units._(function(v1, v2, i, array) {
            return this._(function() {
              return defed.call(global, v1, v2, i, array);
            });
          });
          return units._(function(v) {
            return this.next(v, item, i++, array);
          });
        });
        units._(function(v1, v2, i, array) {
          return this._(function() {
            return defed.call(global, v1, v2, i, array);
          });
        });
        units._(function(result) {
          return this.next(result);
        });
        units.end();
        return unit;
      };
      this.reduceRight = function(array, block, init) {
        return this.reduce(array, block, init, true);
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
          return continuation.next.apply(continuation, args);
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
          return continuation["throw"].apply(continuation, args);
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
          return continuation.next.apply(continuation, args);
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
        return this.previous_unit.invoke();
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
        _results.push(!(p === "self" && (to[p] != null)) ? to[p] = from[p] : void 0);
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
    function Arrays(original) {
      this.original = original;
      this.ziped = Arrays.zip(original);
    }
    Arrays.zip = function(arrays) {
      var array, i, max, _i, _len, _results;
      max = 0;
      for (_i = 0, _len = arrays.length; _i < _len; _i++) {
        array = arrays[_i];
        if (max < array.length) {
          max = array.length;
        }
      }
      _results = [];
      for (i = 0; 0 <= max ? i < max : i > max; 0 <= max ? i++ : i--) {
        _results.push(arrays.map(function(v) {
          return v["" + i];
        }));
      }
      return _results;
    };
    Arrays.prototype.map = function(block, thisp) {
      var result;
      result = [];
            if (thisp != null) {
        thisp;
      } else {
        thisp = global;
      };
      this.ziped.map(function(args, i, _array) {
        args.push(i);
        args.push(_array);
        return result.push(block.apply(thisp, args));
      });
      return result;
    };
    return Arrays;
  })();
  Units = (function() {
    var p, _i, _len, _ref;
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
          } else {
            this.tail = this.tail[p](new Unit(block));
          }
          return this;
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
    var p, _i, _len, _ref;
    function Def(block, use_outer_scope) {
      this.use_outer_scope = use_outer_scope != null ? use_outer_scope : false;
      this.factory = function() {
        return new Units(block);
      };
    }
    _ref = ['_', 'catch'];
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
    Def.prototype.end = function() {
      var defed, factory, use_outer_scope;
      factory = this.factory;
      use_outer_scope = this.use_outer_scope;
      defed = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return begin((function() {
          return this.next.apply(this, args);
        }), this, use_outer_scope)._(factory()).end();
      };
      defed.is_defed = true;
      return defed;
    };
    return Def;
  })();
  begin = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return new Units(args[0], args[1], args[2]);
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
