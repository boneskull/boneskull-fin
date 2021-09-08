local OUTPUT_LEFT = 0
local OUTPUT_CENTER = 1
local OUTPUT_RIGHT = 2
local DIRECTION_IN = 0
local CONVEYOR_TYPE = 0

local function getLoadedItemsFor(producer)
  local inv = producer:getInputInv()
  local result = {}
  for i = 0, inv.size - 1 do
    local stack = inv:getStack(i)
    if stack.item.type then result[stack.item.type.name] = stack.count end
  end
  return result
end

local ingredientCache = {}

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

print('curious router loaded')

local function dumpInventory(obj)

  local function dump(inv)
    if inv then
      local size = inv.size
      print('inventory of size', size)
      local empty = true

      for i = 0, size - 1 do
        local stack = inv:getStack(i)
        if stack.item.type then
          empty = false
          print('stack #', i, '=>', stack.item.type.name, '#', stack.count)
        end
      end

      if empty then print('(empty)') end
    end
  end

  if type(obj.getInventories) == 'function' then
    print('all inventories of', obj)
    for _, inv in ipairs(obj:getInventories()) do dump(inv) end
  elseif type(obj.getInventory) == 'function' then
    local inv = obj:getInventory()
    if inv ~= nil then
      print('inventory of', obj)
      dump(obj:getInventory())
    end
  end
  if type(obj.getFactoryConnectors) == 'function' then
    print('factory connectors in', obj)
    for _, thing in ipairs(obj:getFactoryConnectors()) do
      dumpInventory(thing)
    end
  end
end

local inTransit = {}

local function createItemRequestListener(splitter, producer)
  return function()
    local required = getRequiredItemsFor(producer)
    if splitter:getInput().type then
      local inputItem = splitter:getInput()
      local item = inputItem.type.name
      if required[item] ~= nil then
        local reqLessTransferred = required[item] - (inTransit[item] or 0)
        if reqLessTransferred > 0 then
          -- print('need', reqLessTransferred, item)
          if splitter:canOutput(OUTPUT_LEFT) then
            if splitter:transferItem(OUTPUT_LEFT) then
              if inTransit[item] == nil then
                inTransit[item] = 0
              end
              inTransit[item] = inTransit[item] + 1
            end
          else
            -- print('overflow!')
            splitter:transferItem(OUTPUT_RIGHT)
          end
        else
          -- print('excess of', item)
          splitter:transferItem(OUTPUT_RIGHT)
        end
      else
        if splitter:canOutput(OUTPUT_CENTER) then
          splitter:transferItem(OUTPUT_CENTER)
        else
          splitter:transferItem(OUTPUT_RIGHT)
        end
      end
    end
  end
end

local function createItemTransferListener(conn)
  return function(item)
    if item and item.type then
      local name = item.type.name
      inTransit[name] = (inTransit[name] or 1) - 1
    end
  end
end

local function getConnectedInput(actor)
  if type(actor.getFactoryConnectors) == 'function' then
    for _, conn in ipairs(actor:getFactoryConnectors()) do
      if conn.isConnected and conn.direction == DIRECTION_IN and conn.type == CONVEYOR_TYPE then
        return conn
      end
    end
  end
end

local function setup(tuples)
  local evtMap = {}

  for _, tuple in ipairs(tuples) do
    local splitter =
    component.proxy(component.findComponent(tuple[1]))[1]
    local producer = component.proxy(component.findComponent(tuple[2]))[1]
    print('routing splitter/producer pair', splitter:getHash(), '/', producer:getHash())
    event.listen(splitter)
    event.listen(producer)

    local conn = getConnectedInput(producer)
    local itemTransferListener = createItemTransferListener(conn)
    local itemReqListener = createItemRequestListener(splitter, producer)

    evtMap[conn:getHash()] = {ItemTransfer = itemTransferListener}
    evtMap[splitter:getHash()] = {ItemRequest = itemReqListener}
  end

  while true do
    local evt, actor, param = event.pull(0)
    if actor then
      local hash = actor:getHash()
      if evtMap[hash] and evtMap[hash][evt] then 
        -- print('dispatching listener for event', evt, 'for', actor, actor:getHash())
        evtMap[hash][evt](param) 
      end
    end
  end
end

setup({
  {'beefalo_splitter_curious_pcb', 'beefalo_curious_pcb'},
  {'beefalo_splitter_curious_organic', 'beefalo_curious_organic'},
  {'beefalo_splitter_curious_adapter', 'beefalo_curious_adapter'}
})

