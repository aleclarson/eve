
require "LazyVar"

{frozen} = require "Property"

emptyFunction = require "emptyFunction"
assertTypes = require "assertTypes"
isDev = require "isDev"
Type = require "Type"

ListenerArray = require "./ListenerArray"
Listener = require "./Listener"

type = Type "Event"

type.defineArgs
  id: String.Maybe
  types: Object.Maybe
  async: Boolean.Maybe

type.defineFrozenValues (options) ->

  id: options.id

  _async: options.async

type.defineValues (options = {}) ->

  types: options.types

  _events: options._events

  _listeners: null unless options._events

type.defineGetters

  hasListeners: ->
    listeners = @_listeners or @_events._map[@id]
    return listeners._length > 0

type.defineFunction (callback) ->
  if @_events
  then @_events.on @id, callback
  else @_attach callback

type.defineMethods

  bindEmit: ->
    @_boundEmit or @_bindEmit()

  applyEmit: (args) ->
    @emit.apply this, args

  emit: (data) ->

    if isDev and @types
      assertTypes data, @types

    if @_events
      return @_events.applyEmit @id, arguments

    if @_listeners
      return @_listeners.notify arguments

  once: (callback) ->
    if @_events
    then @_events.once @id, callback
    else @_attach ->
      @detach()
      callback.apply this, arguments

  _attach: (callback) ->

    unless @_listeners
      @_listeners = ListenerArray
        async: @_async
        onAttach: @_onAttach.bind this

    listener = Listener callback, @_onDetach
    return @_listeners.attach listener

  _onAttach: (listener) ->
    Event.didAttach.emit listener, this

  _onDetach: emptyFunction

  _bindEmit: ->
    frozen.define this, "_boundEmit", {value: @emit.bind this}
    return @_boundEmit

type.defineStatics

  Listener: Listener

  Map: lazy: -> require "./EventMap"

  installMixin: -> require "./EventMixin"

  getListeners: (callback) ->
    listeners = []
    onAttach = @didAttach (listener) ->
      listeners.push listener
    callback()
    onAttach.detach()
    return listeners

  didAttach: get: ->

    frozen.define this, "didAttach",
      value: didAttach = Event()

    # Prevent 'didAttach' from triggering itself.
    frozen.define didAttach, "_onAttach",
      value: emptyFunction

    return didAttach

module.exports = Event = type.build()
