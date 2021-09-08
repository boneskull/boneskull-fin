local network = computer.getPCIDevices(findClass("NetworkCard_C"))[1]

local CONTAINER_MK1_TYPE = 'Build_StorageContainerMk1_C'
local CONTAINER_MK2_TYPE = 'Build_StorageContainerMk2_C'
local CONTAINER_MK1_MAX_STACKS = 24
local CONTAINER_MK2_MAX_STACKS = 48

local mk1ContainerIDs = component.findComponent(findClass(CONTAINER_MK1_TYPE))
local mk2ContainerIDs = component.findComponent(findClass(CONTAINER_MK2_TYPE))
local containerToItem = {}
local itemToContainers = {}
local itemNameToItemType = {}

local function getInvItemType(inv)
    inv:sort()
    local size = inv.size
    local itemType
    for i = 0, size do
        -- getStack is 0-indexed
        local itemStack = inv:getStack(i)
        if itemStack ~= nil and itemStack.item.type ~= nil then
            itemType = itemStack.item.type
            break
        end
    end
    return itemType
end

local function refresh()
    local function updateContainer(container)
        if container ~= nil then
            local inv = container:getInventories()[1]
            local maxStacks = inv.size
            local itemType = getInvItemType(inv)
            if itemType then
                containerToItem[container.nick] = itemType
                if not itemToContainers[itemType.name] then
                    itemToContainers[itemType.name] = {}
                end
                itemToContainers[itemType.name][container.nick] = container
                itemNameToItemType[itemType.name] = itemType
            end
        end
    end

    for _, id in ipairs(mk1ContainerIDs) do
        updateContainer(component.proxy(id))
    end

    for _, id in ipairs(mk2ContainerIDs) do
        updateContainer(component.proxy(id))
    end
end

local function getFillPctForItemType(itemType)
    local containers = itemToContainers[itemType.name]
    if containers then
        local totalMaxStacks = CONTAINER_MK1_MAX_STACKS +
                                   CONTAINER_MK2_MAX_STACKS
        local totalItemCount = 0
        for _, container in pairs(containers) do
            local inv = container:getInventories()[1]
            totalItemCount = totalItemCount + inv.itemCount
        end
        print('found', totalItemCount, 'of', itemType.name, 'in',
              totalMaxStacks, 'stacks with', itemType.max, '/stack')
        return math.ceil(totalItemCount / totalMaxStacks / itemType.max * 100)
    end
    return 0
end

local function getFillPctForItemName(name)
    if not itemNameToItemType[name] then error('unknown item', name) end
    return getFillPctForItemType(itemNameToItemType[name])

end

refresh()

local Plotter = {}
Plotter.__index = Plotter
function Plotter:createWithScreen(screen)
    if not screen then error('screen required') end
    local plotter = {}
    setmetatable(plotter, Plotter)
    local gpu = computer.getPCIDevices(findClass("GPUT1"))[1]
    if not gpu then error('gpu not found') end
    return plotter:setup(gpu, screen)
end

function Plotter:create()
    local plotter = {}
    setmetatable(plotter, Plotter)
    local gpu = computer.getPCIDevices(findClass("GPUT1"))[1]
    if not gpu then error('gpu not found') end

    local screen = computer.getPCIDevices(findClass("FINComputerScreen"))[1]
    if not screen then
        local comp = component.findComponent(findClass("Screen"))[1]
        if comp then screen = component.proxy(comp) end
    end
    if not screen then error('screen not found') end

    return plotter:setup(gpu, screen)
end

function Plotter:setup(gpu, screen)
    if not screen and gpu then error('gpu and screen required') end
    gpu:bindScreen(screen)
    gpu:setSize(4, 3)
    local w, h = gpu:getSize()
    -- self.width = w / 2
    -- self.height = h / 2
    -- gpu:setSize(self.width, self.height)
    self.width = w
    self.height = h
    self.gpu = gpu
    self.screen = screen
    self.ready = true
    self:clear()
    print('plotter created with width', self.width, 'and height', self.height)
    return self
end

function Plotter:clear()
    if not self.ready then error('plotter not ready') end
    self.gpu:setBackground(0, 0, 0, 0)
    self.gpu:fill(0, 0, self.width, self.height, ' ')
    self.gpu:flush()
end

function Plotter:setText(x, y, text)
    if not self.ready then error('plotter not ready') end
    self.gpu:setForeground(1, 1, 1, 1)
    self.gpu:setText(x, y, text)
    self.gpu:flush()
end

function split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function displayPcts()
    local displayIds = component.findComponent(findClass('MCP_1Point_C'))
    for _, id in pairs(displayIds) do
        local c = component.proxy(id)
        local itemName = split(c.nick, '_')[2]
        print(itemName)
        local pct = getFillPctForItemName(itemName)
        local mod = c:getModules()[1]

        if pct == 100 then
            mod:setColor(0, 0, 255, 1)
        elseif pct >= 80 then
            mod:setColor(0, 255, 0, 1)
        elseif pct >= 50 then
            mod:setColor(0, 255, 255, 1)
        else
            mod.setColor(255, 0, 0, 1)
        end
        mod:setText(pct)
    end
end

displayPcts()
-- local plotter = Plotter:createWithScreen(component.proxy(
--                                   component.findComponent('display_steel-pipe'))[1])
-- plotter:setText(0, 1, getFillPctForItemName('Steel Pipe')..'%')
