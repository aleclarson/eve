
emptyFunction = require "emptyFunction"
assertType = require "assertType"
Type = require "Type"

type = Type "Listener"

type.defineArgs ->
  types: [Function, Function.Maybe]

type.defineValues (listener, onDetach) ->

  _notify: listener

  _listeners: null

  _onDetach: onDetach or emptyFunction

type.defineGetters

  isListening: -> @_notify isnt null

type.defineMethods

  notify: (args) ->
    @_notify?.apply this, args
    return

  detach: ->

    @_notify = null
    @detach = emptyFunction
    @onDetach = emptyFunction

    if @_listeners
      @_listeners.detach this
      @_listeners = null

    @_onDetach this
    @_onDetach = null
    return

  onDetach: (callback) ->
    assertType callback, Function

    if @_onDetach is emptyFunction
      @_onDetach = callback
      return

    previous = @_onDetach
    @_onDetach = (listener) ->
      previous listener
      callback listener
    return

module.exports = Listener = type.build()
