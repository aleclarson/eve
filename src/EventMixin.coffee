
{frozen} = require "Property"

Type = require "Type"

Event = require "./Event"

Type.extend "defineEvents", (events) ->
  @initInstance ->
    for key, types of events
      options = if types then {types} else undefined
      frozen.define this, key, value: Event options
    return
