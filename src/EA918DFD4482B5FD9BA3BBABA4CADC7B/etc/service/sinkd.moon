require 'dump'
-- eventLib = require 'event'
{:autoSink} = require 'autosink'
buffer = require 'buffer'
json = require 'json'

main = () -> 
  print 'sinkd started'
  OUTPUT_CENTER = 1
  OUTPUT_RIGHT = 2
  

  -- stack_sizes = [si.item_stack_sizes[name] for name in ipairs items]
  -- p stack_sizes
  -- sinkable = [item for item in ipairs items when si\shouldSink item]
  -- p sinkable
  -- p si.item_stack_sizes['Plastic'] * si.item_container_sizes['Plastic']
  -- p si.item_counts['Plastic']

  -- for name, count in pairs si.item_counts
  --   if count == si.item_stack_sizes[name] * si.item_container_sizes[name]
  --     print "#{name} is full"

  configFile = buffer.create('r', filesystem.open '/etc/sinkd.json')
  config = json.decode(configFile\read 'a')
  configFile\close!

  p config
  si = autoSink config.site, config.container_classes
  
  splitterId = component.findComponent(config.splitter)[1]
  splitter = component.proxy splitterId

  itemListener = (target, item) ->
    if target == splitter
      {:type} = item
      if type
        {:name} = type
        output = if si\isSinkable name then OUTPUT_RIGHT else OUTPUT_CENTER
        result = false
        while not result
          result = splitter\transferItem output
          -- if result            
          --   if output == OUTPUT_CENTER
          --     print "+ STORE: #{name}"
          --   else
          --     print "- SINK: #{name}"

    else
      p target

  
  itemListener splitter, splitter\getInput!
  event.listen splitter
  print 'sinkd listening'
  while true
    evt, target, item = event.pull(0)
    if evt == 'ItemRequest'
      itemListener target, item
    elseif not evt
      itemListener splitter, splitter\getInput!
    coroutine.yield!
    computer.skip!

main!
