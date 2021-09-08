local MAIN_PANEL = 'goblin_main_ctrl'
local SWITCH_HASH = 2133245746
local INDICATOR_HASH = 450402650
local TEXT_DISP = 3875372182
local REFINERY = 'goblin_refinery_concrete'

local function getComponent(name)
  return component.proxy(component.findComponent(name))[1]
end

local mainPanel = getComponent(MAIN_PANEL)
local refinery = getComponent(REFINERY)

local moduleCache = {}

local function wait()
  return event.pull(0.0)
end

local function getModule(panel, hash)
  if not moduleCache[panel] then
    moduleCache[panel] = {}
  end
  if moduleCache[panel][hash] then
    print('returning cached mod', moduleCache[panel][hash])
    return moduleCache[panel][hash]
  end
  for _, mod in ipairs(panel:getModules()) do
    print('found mod', mod, 'with hash', mod.hash)
    moduleCache[panel][mod.hash] = mod
    if mod.hash == hash then
      return mod
    end
  end
  error("unable to find module with hash", hash)
end


local indicator = getModule(mainPanel, INDICATOR_HASH)

local function updateIndicator()
  if refinery.standby then
    indicator:setColor(255, 0, 0, 0.01)
    print('refinery in standby')
  else
    indicator:setColor(0, 255, 0, 0.01)
    print('refinery active')
  end
end

local function switchCoroutine()
  updateIndicator()
  local switch = getModule(mainPanel, SWITCH_HASH)
  event.listen(switch)
  while true do
    local evt, component, value = wait()
    if evt then
      print(evt)
    end
    if evt == 'ChangeState' then
      refinery.standby = not value
      updateIndicator()
    end
  end
end

local counter = 0
local function textCoroutine()
  local txt = getModule(mainPanel, TEXT_DISP)
  local ms = computer.millis()
  while true do
    wait()
    if computer.millis() - ms >= 5000 then
      counter = counter + 1
      txt.setText(counter)
      ms = computer.millis()
    end
  end
end


local switchThread = thread.create(switchCoroutine)
-- local textThread = thread.create(textCoroutine)

thread.run()

