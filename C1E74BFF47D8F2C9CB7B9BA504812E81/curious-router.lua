dump = function(value)
  local seen = { }
  local _dump
  _dump = function(what, depth)
    if depth == nil then
      depth = 0
    end
    local t = type(what)
    if t == "string" then
      return '"' .. what .. '"\n'
    elseif t == "table" then
      if seen[what] then
        return "recursion(" .. tostring(what) .. ")...\n"
      end
      seen[what] = true
      depth = depth + 1
      local lines
      do
        local _accum_0 = { }
        local _len_0 = 1
        for k, v in pairs(what) do
          _accum_0[_len_0] = (" "):rep(depth * 4) .. "[" .. tostring(k) .. "] = " .. _dump(v, depth)
          _len_0 = _len_0 + 1
        end
        lines = _accum_0
      end
      seen[what] = false
      local class_name
      if what.__class then
        class_name = "<" .. tostring(what.__class.__name) .. ">"
      end
      return tostring(class_name or "") .. "{\n" .. table.concat(lines) .. (" "):rep((depth - 1) * 4) .. "}\n"
    else
      return tostring(what) .. "\n"
    end
  end
  return _dump(value)
end
p = function(...)
  return print(dump(...))
end

local OUTPUT_LEFT = 0
local OUTPUT_CENTER = 1
local OUTPUT_RIGHT = 2
local DIRECTION_IN = 0
local CONVEYOR_TYPE = 0
local TIMEOUT = 1.0 -- how long to wait in seconds for an event before manually routing

-- get the items in a producer's input inventory
local function getLoadedItemsFor(producer)
  local inv = producer:getInputInv()
  local result = {}
  for i = 0, inv.size - 1 do
    local stack = inv:getStack(i)
    if stack.item.type then result[stack.item.type.name] = stack.count end
  end
  return result
end

-- cache of recipe ingredients per producer
local ingredientCache = {}

-- track items on belts
local inTransit = {}

-- determines the count of currently needed items for a producer
local function getRequiredItemsFor(producer)
  local ingredients
  if ingredientCache[producer:getHash()] then
    ingredients = ingredientCache[producer:getHash()]
  else
    local recipe = producer:getRecipe()
    ingredients = recipe:getIngredients()
    ingredientCache[producer:getHash()] = ingredients
  end
  local loadedItems = getLoadedItemsFor(producer)
  local result = {}
  for _, ingredient in ipairs(ingredients) do
    local amount = ingredient.type.max
    local name = ingredient.type.name
    result[name] = amount - (loadedItems[name] or 0)
  end
  return result
end

-- returns a function which determines where to send an item.
-- each splitter executes said function when its `ItemRequest` event fires
local function createItemRequestListener(splitter, producer)
  return function()
    local required = getRequiredItemsFor(producer)
    if splitter:getInput().type then
      local inputItem = splitter:getInput()
      local item = inputItem.type.name
      if required[item] ~= nil then
        local producerHash = producer:getHash()
        if inTransit[producerHash] == nil then
          inTransit[producerHash] = {}
        end
        local reqLessTransferred = required[item] -
                                       (inTransit[producerHash][item] or 0)
        if reqLessTransferred > 0 then 
          -- print('need', reqLessTransferred, item)
          if splitter:canOutput(OUTPUT_LEFT) then
            if splitter:transferItem(OUTPUT_LEFT) then
              -- print(item, '=> LEFT')
              if inTransit[producerHash][item] == nil then
                inTransit[producerHash][item] = 0
              end
              inTransit[producerHash][item] = inTransit[producerHash][item] + 1
              return
            end
          else
            if splitter:canOutput(OUTPUT_CENTER) then
              -- print(item, '=> CENTER')
              if splitter:transferItem(OUTPUT_CENTER) then return end
            end
          end
        end
      end
      if splitter:canOutput(OUTPUT_CENTER) then
        -- print(item, '=> CENTER')
        if splitter:transferItem(OUTPUT_CENTER) then return end
      end
      -- print(item, '=> RIGHT')
      while true do if splitter:transferItem(OUTPUT_RIGHT) then return end end
    end
  end
end

-- creates a function which decrements the count of in-transit items
-- for a given producer. run when the `ItemTransfer` event of the producer's
-- factory connection fires
local function createItemTransferListener(producer)
  local producerHash = producer:getHash()
  return function(item)
    if item and item.type then
      local name = item.type.name
      inTransit[producerHash][name] = (inTransit[producerHash][name] or 1) - 1
    end
  end
end

-- finds the relevant factory connection. there's going to be a single input belt, and
-- this returns the connection for that.
local function getConnectedInput(actor)
  if type(actor.getFactoryConnectors) == 'function' then
    for _, conn in ipairs(actor:getFactoryConnectors()) do
      if conn.isConnected and conn.direction == DIRECTION_IN and conn.type ==
          CONVEYOR_TYPE then return conn end
    end
  end
end

-- configures all the things. expects a table of pairs of splitters & producers.
local function setup(tuples)
  local evtMap = {}

  -- This just runs all of the listener functions in case an event was missed.
  local function kickstart()
    print('kickstarting...')
    -- for producerHash, itemMap in pairs(inTransit) do for itemName in pairs(itemMap) do inTransit[producerHash][itemName] = 0 end end
    for _, map in pairs(evtMap) do for _, func in pairs(map) do func() end end
  end

  for _, tuple in ipairs(tuples) do
    local splitter = component.proxy(component.findComponent(tuple[1]))[1]
    local producer = component.proxy(component.findComponent(tuple[2]))[1]
    print('routing splitter/producer pair', splitter:getHash(), '/',
          producer:getHash())
    event.listen(splitter)
    event.listen(producer)

    local conn = getConnectedInput(producer)
    local itemTransferListener = createItemTransferListener(producer)
    local itemReqListener = createItemRequestListener(splitter, producer)

    evtMap[conn:getHash()] = {ItemTransfer = itemTransferListener}
    evtMap[splitter:getHash()] = {ItemRequest = itemReqListener}

    -- run this to make sure there isn't anything sitting in a splitter's inventory
    itemReqListener()

    -- TODO: handle case where an item is on a belt from a splitter to producer just before
    -- startup.
  end

  print('configured', #tuples, 'pairs; listening for events')

  while true do    
    local evt, actor, param = event.pull(TIMEOUT)
    if evt and actor then
      local hash = actor:getHash()
      if evtMap[hash] and evtMap[hash][evt] then
        -- print('dispatching listener for event', evt, 'for', actor, actor:getHash())
        evtMap[hash][evt](param)
      end
    else
      -- the event pull can timeout if we miss one.
      kickstart()
    end
    computer.skip()
  end
end

setup({
  {'beefalo_splitter_curious_pcb', 'beefalo_curious_pcb'},
  {'beefalo_splitter_curious_organic', 'beefalo_curious_organic'},
  {'beefalo_splitter_curious_adapter', 'beefalo_curious_adapter'}
})

