require 'dump'

MANUFACTURER_CLASS = 'Build_AlloyFoundry_C'
DIRECTION_IN = 0
CONVEYOR_TYPE = 0

main = () ->
  manufacturerIds = component.findComponent(findClass MANUFACTURER_CLASS)
  manufacturers = [component.proxy id for _, id in ipairs manufacturerIds]

  getActiveManufacturers = () -> [m for _, m in ipairs manufacturers when m.standby == false] 

  active_manufacturers = getActiveManufacturers!
  if not #active_manufacturers
    print 'no active manufacturers; exiting'
    return
  else
    print "found #{#active_manufacturers} active manufacturers; checking..."
  
  needs_sam_ore = {}

  check = (manufacturer) ->
    inv = manufacturer\getInputInv!
    {:size} = inv
    
    found = false
    for slot = 0, size - 1
      stack = inv\getStack slot      
      if stack.item.type and stack.item.type.name == 'SAM Ore'
        found = true
        break
    if not found
      print "disabling manufacturer '#{manufacturer.nick}'"
      manufacturer.standby = true
    else
      print "manufacturer #{manufacturer.nick} has SAM Ore"

  while true
    if not #active_manufacturers
      print 'no active manufacturers; exiting'
      return
    for _, manufacturer in ipairs active_manufacturers
      if needs_sam_ore[manufacturer.nick]
        check manufacturer
      else
        for __, ing in ipairs manufacturer\getRecipe!\getIngredients!
          if ing.type.name == 'SAM Ore'
            needs_sam_ore[manufacturer.nick] = true
            check manufacturer

    active_manufacturers = getActiveManufacturers!
    event.pull 60
    coroutine.yield!

main!
