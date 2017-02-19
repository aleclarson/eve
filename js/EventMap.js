// Generated by CoffeeScript 1.11.1
var Event, Listener, ListenerArray, Type, assertType, isType, sync, type;

assertType = require("assertType");

isType = require("isType");

Type = require("Type");

sync = require("sync");

ListenerArray = require("./ListenerArray");

Listener = require("./Listener");

Event = require("./Event");

type = Type("EventMap");

type.defineArgs({
  only: Array.Maybe
});

type.defineValues(function(options) {
  return {
    _map: Object.create(null),
    _strict: options.only != null,
    _eventIds: new Set(options.only)
  };
});

type.defineMethods({
  emit: function(id, data) {
    var listeners;
    if (!this._strict) {
      this._eventIds.add(id);
    } else if (!this._eventIds.has(id)) {
      throw Error("Unsupported event: '" + id + "'");
    }
    if (listeners = this._map[id]) {
      listeners.notify(data);
    }
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
    return this._attach(id, Listener(callback));
  },
  once: function(id, callback) {
    assertType(id, String);
    assertType(callback, Function);
    return this._attach(id, Listener(function(data) {
      this.detach();
      return callback.call(this, data);
    }));
  },
  _attach: function(id, listener) {
    var listeners;
    assertType(id, String);
    if (this._strict && !this._eventIds.has(id)) {
      throw Error("Unsupported event: '" + id + "'");
    }
    if (!(listeners = this._map[id])) {
      this._map[id] = listeners = ListenerArray();
    }
    listeners.attach(listener);
    return listener;
  }
});

module.exports = type.build();