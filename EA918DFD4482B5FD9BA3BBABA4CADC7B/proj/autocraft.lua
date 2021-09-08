print('running autocraft')

filesystem.doFile('/thread.lua')

local REFINERY = 'goblin_refinery_concrete'
local CONTAINER = 'goblin_container_concrete'
local CONTAINER_MAX_STACKS = 72

local refinery = component.proxy(component.findComponent(REFINERY))[1]
local container = component.proxy(component.findComponent(CONTAINER))[1]
local FCONN_CONVEYOR_TYPE = 0
local FCONN_DIR_OUTPUT = 1


local function getInvItemType(inv)
  inv:sort()
  local size = inv.size
  local itemType
  for i = 0, size do
      -- getStack is 0-indexed
      local itemStack = inv:getStack(i)
      if itemStack and itemStack.item.type then
          itemType = itemStack.item.type
          break
      end
  end
  return itemType
end
local containerToItem = {}
local inv = container:getInventories()[1]
local itemType = getInvItemType(inv)
local maxItemCount = CONTAINER_MAX_STACKS * itemType.max
local itemCount = inv.itemCount

local toCraft = maxItemCount - itemCount

for _, conn in pairs(refinery:getFactoryConnectors()) do
  if conn.isConnected and conn.type == FCONN_CONVEYOR_TYPE and conn.direction == FCONN_DIR_OUTPUT then
    print('found output conveyor')
  end
  
end


local function craft(count)
  if not count or count == 0 then
    print('done')
    return
  end

  refinery.standby = false

  event.listen(refinery)
  print('waiting for event from refinery')
  print('refinery standby?', refinery.standby)
  local event, sender, params = event.pull()
  print(event)
  print(sender)
  print(params)
  
  refinery.standby = true
  event.ignore(refinery)
end

local panel = component.proxy(component.findComponent('ctrl'))[1]
local lever = panel:getModules()[1]
event.listen(lever)
print('waiting for lever')
print(event.pull())

print('waiting for lever againa')
print(event.pull())
-- craft(1)
-- aw

-- if toCraft == 0 then
--   refinery.standby = true
-- else
--   refinery.standby = false



