
emptyFunction = require "emptyFunction"
assertType = require "assertType"
immediate = require "immediate"
Type = require "Type"

Listener = require "./Listener"

type = Type "ListenerArray"

type.defineArgs
  async: Boolean.Maybe
  onAttach: Function.Maybe

type.defineValues (options) ->

  _value: null

  _length: 0

  _isNotifying: no

  _onAttach: options.onAttach or emptyFunction

  _detached: []

  _queue: [] if options.async

type.defineGetters

  length: -> @_length

  isNotifying: -> @_isNotifying

type.defineMethods

  attach: (listener) ->

    assertType listener, Listener
    listener._listeners = this

    if oldValue = @_value
      if oldValue.constructor is Listener
      then @_update [oldValue, listener], 2
      else @_update oldValue, oldValue.push listener
    else @_update listener, 1

    @_onAttach listener
    return listener

  notify: (args) ->

    # Don't notify (or push to queue) if no listeners are attached.
    return unless @_value

    # Perform synchronous emits.
    unless @_queue
      @_isNotifying = yes
      @_notify args
      @_isNotifying = no
      @_flush()
      return

    # Push to queue if async emit is active.
    if @_isNotifying or @_queue.length
      @_queue.push args
      return

    # Emit immediately after the JS event loop ticks.
    @_notifyAsync args
    return

  detach: (listener) ->

    assertType listener, Listener
    listener._listeners = null

    if @_isNotifying
      @_detached.push listener
      return

    unless oldValue = @_value
      throw Error "No listeners are attached!"

    if oldValue.constructor is Listener

      if listener isnt oldValue
        throw Error "Listener is not attached to this ListenerArray!"

      @_update null, 0
      return

    index = oldValue.indexOf listener
    if index < 0
      throw Error "Listener is not attached to this ListenerArray!"

    oldValue.splice index, 1
    newCount = oldValue.length

    if newCount is 1
    then @_update oldValue[0], 1
    else @_update oldValue, newCount
    return

  reset: ->
    @_update null, 0 if @_length
    return

  _update: (newValue, newLength) ->
    @_value = newValue
    @_length = newLength
    return

  _notify: (args) ->
    if @_length is 1
    then @_value.notify args
    else @_value.forEach (listener) ->
      listener.notify args

  _notifyAsync: (args) ->
    @_isNotifying = yes
    immediate this, ->
      @_value and @_notify args
      @_isNotifying = no
      @_flush()
      if args = @_queue.shift()
        @_notifyAsync args
      return
    return

  # Flushes the queue of listeners that need detaching.
  _flush: ->

    {length} = listeners = @_detached
    return if length is 0

    if length is 1
      @detach listeners.pop()
      return

    index = -1
    @detach listeners[index] while ++index < length
    listeners.length = 0
    return

module.exports = type.build()
