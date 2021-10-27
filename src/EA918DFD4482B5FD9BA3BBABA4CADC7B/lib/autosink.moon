require 'dump'

-- "Big Industrial Storage Container"
-- BASIC_CONTAINER_CLASS_NAME = 'Build_1_C'
-- BASIC_CONTAINER_INV_SIZE = 72
-- "Monstrous Storage Container"
-- LARGE_CONTAINER_CLASS_NAME = 'Build_4_C'
-- LARGE_CONTAINER_INV_SIZE = 498

-- TODO: config file reading

siteAutoSinks = {}

DEFAULT_CONTAINER_CLASS = 'Build_1_C'

class SiteAutoSink
  new: (name, container_classes) => 
    @name = name    
    @container_classes = container_classes
    @container_ids = nil
    @sinkable = {}

    @updateSinkables!
    print "instantiated new SiteAutoSink"

  isSinkable: (name) => @sinkable[name] == true
  -- shouldSink: (name) =>
  --   if @item_stack_sizes[name] ~= nil and @item_container_sizes[name] ~= nil
  --     return (@item_stack_sizes[name] * @item_container_sizes[name]) == (@item_counts[name] or 0)
  --   false

  updateContainers: () =>
    container_ids = {}
    for _, container_cls in ipairs @container_classes      
      container_cls_ids = component.findComponent(findClass container_cls)
      for __, id in ipairs container_cls_ids
        table.insert(container_ids, id)
    @container_ids = container_ids  
    print "found #{#@container_ids} containers"

  updateSinkables: () =>
    if not @container_ids then @updateContainers!
  
    stats = {
      item_names: {}
      empty_containers: 0
      container_count: #@container_ids
    }
    for _, id in ipairs @container_ids
      container = component.proxy id      
      inv = container\getInventories![1]
      inv\sort!
      {itemCount: item_count, :size} = inv
      {:item} = inv\getStack(1) or {}
      
      if item.type
        {:max, :name} = item.type
        full_count_for_inv = max * size
        @sinkable[name] = full_count_for_inv == item_count
        table.insert(stats.item_names, name)
      else
        stats.empty_containers = stats.empty_containers + 1
      
    print "updated sinkable status for #{#stats.item_names} discrete items"
    stats

autoSink = (name, container_classes = {}) ->
  if not #container_classes then container_classes = {DEFAULT_CONTAINER_CLASS}
  id = dump { name, container_classes }
  if siteAutoSinks[id] then return siteAutoSinks[id]
  siteAutoSink = SiteAutoSink(name, container_classes)
  siteAutoSinks[id] = siteAutoSink
  siteAutoSink

{:autoSink}
