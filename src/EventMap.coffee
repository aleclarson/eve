
emptyFunction = require "emptyFunction"
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
  async: Boolean.Maybe

type.defineValues (options) ->

  _map: Object.create null

  _async: options.async

  _strict: options.only?

  _eventIds: new Set options.only

  _onEmit: emptyFunction

type.defineMethods

  applyEmit: (id, args) ->
    @emit.apply this, [id].concat args

  emit: (id, data) ->

    if not @_strict
      @_eventIds.add id
    else if not @_eventIds.has id
      throw Error "Unsupported event: '#{id}'"

    if listeners = @_map[id]
      listeners.notify data

    @_onEmit.apply null, arguments
    return

  bind: (id, types) ->
    assertType id, Object.or String
    assertType types, Object.Maybe

    if isType id, String
      return Event {id, types, _events: this}

    return sync.map arguments[0], (types, id) =>
      Event {id, types, _events: this}

  on: (id, callback) ->
    assertType id, String
    assertType callback, Function
    @_attach id, callback

  once: (id, callback) ->
    assertType id, String
    assertType callback, Function
    @_attach id, (data) ->
      @detach()
      callback.call this, data

  _attach: (id, callback) ->

    if @_strict and not @_eventIds.has id
      throw Error "Unsupported event: '#{id}'"

    unless listeners = @_map[id]
      @_map[id] = listeners = ListenerArray
        async: @_async
        onAttach: @_onAttach.bind this

    listener = Listener callback, @_onDetach
    return listeners.attach listener

  _onAttach: (listener) ->
    Event.didAttach.emit listener, this

  _onDetach: emptyFunction

module.exports = type.build()
