
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

type.defineMethods

  emit: (data) ->

    if isDev and @types
      assertTypes data, @types

    if @_events
      return @_events.emit @id, data

    if @_listeners
      return @_listeners.notify data

  on: (callback) ->
    if @_events
    then @_events.on @id, callback
    else @_attach callback

  once: (callback) ->
    if @_events
    then @_events.once @id, callback
    else @_attach (data) ->
      callback.call this, data
      @detach()

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

type.defineStatics

  Listener: Listener

  Map: lazy: -> require "./EventMap"

  installMixin: -> require "./EventMixin"

  getListeners: (callback) ->
    listeners = []
    onAttach = @didAttach.on (listener) ->
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
