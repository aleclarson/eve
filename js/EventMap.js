// Generated by CoffeeScript 1.12.4
var Event, Listener, ListenerArray, Type, assertType, emptyFunction, isType, sliceArray, sync, type;

emptyFunction = require("emptyFunction");

assertType = require("assertType");

sliceArray = require("sliceArray");

isType = require("isType");

Type = require("Type");

sync = require("sync");

ListenerArray = require("./ListenerArray");

Listener = require("./Listener");

Event = require("./Event");

type = Type("EventMap");

type.defineArgs({
  only: Array.Maybe,
  async: Boolean.Maybe
});

type.defineValues(function(options) {
  return {
    _map: Object.create(null),
    _async: options.async,
    _strict: options.only != null,
    _eventIds: new Set(options.only),
    _onEmit: emptyFunction
  };
});

type.defineMethods({
  applyEmit: function(id, args) {
    return this.emit.apply(this, [id].concat(args));
  },
  emit: function(id) {
    var args, listeners;
    if (!this._strict) {
      this._eventIds.add(id);
    } else if (!this._eventIds.has(id)) {
      throw Error("Unsupported event: '" + id + "'");
    }
    args = sliceArray(arguments, 1);
    if (listeners = this._map[id]) {
      listeners.notify(args);
    }
    this._onEmit.apply(null, arguments);
  },
  bind: function(id, types) {
    assertType(id, Object.or(String));
    assertType(types, Object.Maybe);
    if (isType(id, String)) {
      return Event({
        id: id,
        types: types,
        _events: this
      });
    }
    return sync.map(arguments[0], (function(_this) {
      return function(types, id) {
        return Event({
          id: id,
          types: types,
          _events: _this
        });
      };
    })(this));
  },
  on: function(id, callback) {
    assertType(id, String);
    assertType(callback, Function);
    return this._attach(id, callback);
  },
  once: function(id, callback) {
    assertType(id, String);
    assertType(callback, Function);
    return this._attach(id, function() {
      this.detach();
      return callback.apply(this, arguments);
    });
  },
  _attach: function(id, callback) {
    var listener, listeners;
    if (this._strict && !this._eventIds.has(id)) {
      throw Error("Unsupported event: '" + id + "'");
    }
    if (!(listeners = this._map[id])) {
      this._map[id] = listeners = ListenerArray({
        async: this._async,
        onAttach: this._onAttach.bind(this)
      });
    }
    listener = Listener(callback, this._onDetach);
    return listeners.attach(listener);
  },
  _onAttach: function(listener) {
    return Event.didAttach.emit(listener, this);
  },
  _onDetach: emptyFunction
});

module.exports = type.build();
