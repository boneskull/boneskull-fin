require 'dump'

MANUFACTURER_CLASS = 'Manufacturer'
ACTOR_CLASS = 'Actor'


getEfficiency = (nick) ->
  local manufacturerIds
  if nick
    manufacturerIds = component.findComponent nick
  else
    manufacturerIds = component.findComponent(findClass MANUFACTURER_CLASS)
  for _, id in ipairs manufacturerIds
    manufacturer = component.proxy id
    efficiency = math.floor manufacturer.productivity * 100
    print "#{manufacturer.nick}: #{efficiency}%"

getPowerConsumption = (nick) ->
  local actorIds
  if nick
    actorIds = component.findComponent nick
  else
    actorIds = component.findComponent(findClass ACTOR_CLASS)
  
  for _, id in ipairs actorIds
    actor = component.proxy id
    connectors = actor\getPowerConnectors!
    
getEfficiency()

