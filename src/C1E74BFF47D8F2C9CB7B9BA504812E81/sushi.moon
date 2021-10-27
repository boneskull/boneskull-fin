require('util')

OUTPUT_LEFT = 0
OUTPUT_CENTER = 1
OUTPUT_RIGHT = 2
DIRECTION_IN = 0
CONVEYOR_TYPE = 0
TIMEOUT = 2.0 -- how long to wait in seconds for an event before manually routing

-- get the items in a producer's input inventory
getLoadedItemsFor = (producer) ->
  inv = producer\getInputInv!
  result = {}
  for i = 0, inv.size - 1
    stack = inv\getStack i
    if stack.item.type then result[stack.item.type.name] = stack.count     
  result

-- cache of recipe ingredients per producer
ingredientCache = {}

-- determines the count of currently needed items for a producer
getRequiredItemsFor = (producer) ->
  local ingredients
  producerHash = producer\getHash!
  if not ingredientCache[producerHash] then ingredientCache[producerHash] = producer\getRecipe!\getIngredients!
  ingredients = ingredientCache[producerHash]
  loadedItems = getLoadedItemsFor producer
  { ingredient.type.name, ingredient.type.max - (loadedItems[ingredient.type.name] or 0) for _, ingredient in ipairs ingredients }
  

-- track items on belts
inTransit = {}

-- returns a function which determines where to send an item.
-- each splitter executes said function when its `ItemRequest` event fires
createItemRequestListener = (splitter, producer) ->
  () ->
    required = getRequiredItemsFor producer
    producerHash = producer\getHash!

    if itemType = splitter\getInput!.type
      item = itemType.name
      if required[item] ~= nil        
        reqLessTransferred = required[item] - inTransit[producerHash][item]
        if reqLessTransferred > 0 
          if not splitter\transferItem OUTPUT_LEFT
            computer.beep()
          -- print(item, '=> LEFT')
          else
            inTransit[producerHash][item] = inTransit[producerHash][item] + 1
            return
        -- else
        --   print "not sending item #{item} left; required = #{required[item]}, inTransit = #{inTransit[producerHash][item]}, reqLessTransferred = #{reqLessTransferred}"
      while true
          -- print(item, '=> RIGHT')        
        if splitter\transferItem(OUTPUT_CENTER) or splitter\transferItem(OUTPUT_RIGHT) then return
        event.pull 0.0
        
    return

-- creates a function which decrements the count of in-transit items
-- for a given producer. run when the `ItemTransfer` event of the producer's
-- factory connection fires
createItemTransferListener = (producer) ->
  producerHash = producer\getHash!
  (item) ->
    if item and item.type then inTransit[producerHash][item.type.name] = inTransit[producerHash][item.type.name] - 1
    return
      
-- finds the relevant factory connection. there's going to be a single input belt, and
-- this returns the connection for that.
getConnectedInput = (actor) ->
  if type actor.getFactoryConnectors == 'function'
    for _, conn in ipairs actor\getFactoryConnectors!
      if conn.isConnected and conn.direction == DIRECTION_IN and conn.type == CONVEYOR_TYPE 
        print "found input factory connection for actor #{actor\getHash!}"
        return conn       
  
  print "no getFactoryConnectors on actor #{actor}"
  return

initInTransitTable = (producerHash, reqdItems) ->
  inTransit[producerHash] = {}
  for name in pairs reqdItems do inTransit[producerHash][name] = 0
    
-- if multiple producers require the same item, we should deliver the items round-robin style.
-- findCommonIngredients = (producers) ->
--   producerHashes = {producer\getHash! for producer in ipairs producers}

-- configures all the things. expects a table of pairs of splitters & producers.
setup = (tuples) ->
  evtMap = {}

  -- This just runs all of the listener functions in case an event was missed.
  kickstart = () ->
    print 'kickstarting...'
    -- for producerHash, itemMap in pairs(inTransit) for itemName in pairs(itemMap) inTransit[producerHash][itemName] = 0 end     
    for _, funcMap in pairs evtMap
      for evt, func in pairs funcMap
        if evt == 'ItemRequest' then func!
        
    return

  producerHashes = {}

  for _, tuple in ipairs tuples
    {splitterId, producerId} = tuple
    splitter = component.proxy(component.findComponent splitterId)[1]
    producer = component.proxy(component.findComponent producerId)[1]
    splitterHash = splitter\getHash!
    producerHash = producer\getHash!

    table.insert producerHashes, producerHash
    reqdItems = getRequiredItemsFor producer
    p reqdItems
    initInTransitTable producerHash, reqdItems
    
    print "routing splitter/producer pair #{splitter\getHash!}/#{producer\getHash!}"
    
    event.listen splitter
    conn = getConnectedInput producer
    event.listen conn
    connHash = conn\getHash!

    itemTransferListener = createItemTransferListener producer
    itemReqListener = createItemRequestListener splitter, producer

    evtMap[connHash] = {ItemTransfer: itemTransferListener}
    evtMap[splitterHash] = {ItemRequest: itemReqListener}

    -- run this to make sure there isn't anything sitting in a splitter's inventory
    print 'running initial ItemRequest listener'
    itemReqListener!

    -- TODO: handle case where an item is on a belt from a splitter to producer just before
    -- startup.
  
  print "configured #{#tuples} pairs; listening for events"

  while true    
    evt, actor, arg = event.pull TIMEOUT

    if actor and (evt == 'ItemTransfer' or evt == 'ItemRequest')
      hash = actor\getHash!
      if evtMap[hash] and evtMap[hash][evt] then evtMap[hash][evt] arg
    elseif not actor
      -- the event pull can timeout if we miss one.
      kickstart!
  
setup {
  {'beefalo_splitter_curious_pcb', 'beefalo_curious_pcb'},
  {'beefalo_splitter_curious_organic', 'beefalo_curious_organic'},
  {'beefalo_splitter_curious_adapter', 'beefalo_curious_adapter'}
}

