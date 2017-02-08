
require "LazyVar"

{frozen} = require "Property"

assertTypes = require "assertTypes"
isDev = require "isDev"
Type = require "Type"

ListenerArray = require "./ListenerArray"
Listener = require "./Listener"

type = Type "Event"

type.defineArgs
  id: String.Maybe
  types: Object.Maybe

type.defineFrozenValues (options) ->

  id: options.id

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
    else @_on callback

  once: (callback) ->
    if @_events
    then @_events.once @id, callback
    else @_on (data) ->
      callback.call this, data
      @detach()

  _on: (callback) ->

    unless @_listeners
      @_listeners = ListenerArray
        onAttach: @_onAttach.bind this

    listener = Listener callback
    @_listeners.attach listener
    return listener

  _onAttach: (listener) ->
    Event.didAttach.emit listener, this

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
