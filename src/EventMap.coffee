
assertType = require "assertType"
isType = require "isType"
Type = require "Type"
sync = require "sync"

ListenerArray = require "./ListenerArray"
Listener = require "./Listener"
Event = require "./Event"

type = Type "EventMap"

type.defineArgs
  only: Array.Maybe

type.defineValues (options) ->

  _map: Object.create null

  _strict: options.only?

  _eventIds: new Set options.only

type.defineMethods

  emit: (id, data) ->

    if not @_strict
      @_eventIds.add id
    else if not @_eventIds.has id
      throw Error "Unsupported event: '#{id}'"

    if listeners = @_map[id]
      listeners.notify data
    return

  bind: (id, types) ->
    assertType id, Object.or String
    assertType types, Object.Maybe

    if isType id, String
      return Event {id, types, _events: this}

    return sync.map arguments[0], (types, id) =>
      Event {id, types, _events: this}

  on: (id, callback) ->
    @_attach id, Listener callback

  once: (id, callback) ->
    assertType id, String
    assertType callback, Function
    @_attach id, Listener (data) ->
      @detach()
      callback.call this, data

  _attach: (id, listener) ->
    assertType id, String

    if @_strict and not @_eventIds.has id
      throw Error "Unsupported event: '#{id}'"

    unless listeners = @_map[id]
      @_map[id] = listeners = ListenerArray()

    listeners.attach listener
    return listener

module.exports = type.build()
