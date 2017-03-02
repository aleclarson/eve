
{frozen} = require "Property"

Type = require "Type"

Event = require "./Event"

Type.extend "defineEvents", (events) ->
  @initInstance ->
    ctr = @constructor.name
    for key, types of events
      frozen.define this, key,
        value: Event {id: ctr + "." + key, types}
    return
