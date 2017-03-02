
describe "Event", ->

  Event = require "../js/Event"

  it "provides an 'on' and 'emit' method", ->
    event = Event()
    event.on spy = jasmine.createSpy()

    event.emit 1
    expect spy.calls.argsFor 0
      .toEqual [1]

    event.emit 2
    expect spy.calls.argsFor 1
      .toEqual [2]

  it "provides a 'once' method", ->
    event = Event()
    listener = event.once spy = jasmine.createSpy()

    event.emit 1
    expect spy.calls.argsFor 0
      .toEqual [1]

    expect listener.isListening
      .toBe no

    event.emit 2
    expect spy.calls.argsFor 1
      .toEqual []

  it "validates emitted data with 'options.types'", ->
    types = {foo: Number}
    event = Event {types}

    expect -> event.emit()
      .toThrowError "Expected an Object!"

    expect -> event.emit {foo: "string"}
      .toThrowError "'foo' must be a Number!"

    expect -> event.emit {foo: 1}
      .not.toThrow()

  it "provides its '_onDetach' method to every Listener", ->

    event = Event()
    event._onDetach = spy = jasmine.createSpy()

    l1 = event.once ->
    l2 = event.once ->

    event.emit()
    expect spy.calls.count()
      .toBe 2

  describe "Event.getListeners", ->

    it "returns an array of listeners attached inside your callback", ->
      event = Event()
      expected = []
      listeners = Event.getListeners ->
        listener = event.once emptyFunction
        expected.push listener
        listener = event.once emptyFunction
        expected.push listener
        return
      expect listeners
        .toEqual expected

  describe "Event.installMixin", ->
    Type = require "Type"

    it "provides a 'defineEvents' method on the 'Type' prototype", ->
      {prototype} = Type.Builder
      expect prototype.defineEvents
        .toBe undefined

      Event.installMixin()
      expect prototype.defineEvents
        .not.toBe undefined

    it "creates Event properties using the value as 'options.types'", ->
      type = Type()
      type.defineEvents
        foo: null
        bar: {x: Number, y: Number}
      Foo = type.build()
      obj = Foo()
      expect -> obj.foo.emit()
        .not.toThrow()
      expect -> obj.bar.emit()
        .toThrowError "Expected an Object!"
      expect -> obj.bar.emit {x: 1}
        .toThrowError "'y' must be a Number!"
      expect -> obj.bar.emit {x: 1, y: 2}
        .not.toThrow()

describe "Event.Map", ->

  EventMap = require "../js/EventMap"

  it "uses unique ids to dispatch events", ->
    events = EventMap()
    events.on "foo", spy = jasmine.createSpy()

    events.emit "foo", 1
    expect spy.calls.argsFor 0
      .toEqual [1]

    events.emit "foo", 2
    expect spy.calls.argsFor 1
      .toEqual [2]

  it "allows binding a global id to an Event", ->
    events = EventMap()
    event = events.bind "foo"
    event.on spy = jasmine.createSpy()
    events.on "foo", spy2 = jasmine.createSpy()

    event.emit 1
    expect spy.calls.argsFor 0
      .toEqual [1]

    event.emit 2
    expect spy.calls.argsFor 1
      .toEqual [2]

    expect spy.calls.allArgs()
      .toEqual spy2.calls.allArgs()

  it "provides a 'once' method", ->
    events = EventMap()
    listener = events.once "foo", spy = jasmine.createSpy()

    events.emit "foo", 1
    expect spy.calls.argsFor 0
      .toEqual [1]

    expect listener.isListening
      .toBe no

    events.emit "foo", 2
    expect spy.calls.argsFor 1
      .toEqual []

  it "provides its '_onDetach' method to every Listener", ->

    events = EventMap()
    events._onDetach = spy = jasmine.createSpy()

    l1 = events.once "foo", ->
    l2 = events.once "foo", ->

    events.emit "foo"
    expect spy.calls.count()
      .toBe 2

describe "Event.Listener", ->

  emptyFunction = require "emptyFunction"
  Listener = require "../js/Listener"

  it "starts listening immediately", ->
    listener = Listener emptyFunction
    expect listener.isListening
      .toBe yes

  it "provides a 'notify' method", ->
    listener = Listener spy = jasmine.createSpy()
    listener.notify 1
    expect spy.calls.argsFor 0
      .toEqual [1]

  it "provides a 'detach' method", ->
    listener = Listener spy = jasmine.createSpy()
    listener.detach()
    listener.notify 1
    expect spy.calls.count()
      .toBe 0

  it "accepts an 'onDetach' function as the second argument", ->
    listener = Listener emptyFunction, spy = jasmine.createSpy()
    listener.detach()
    expect spy.calls.argsFor 0
      .toEqual [listener]
