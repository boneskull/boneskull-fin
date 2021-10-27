require 'dump'
{:autoSink} = require 'autosink'
buffer = require 'buffer'
json = require 'json'
{:sleep} = require 'util'

main = () ->
  print 'sinkcopd started'
  -- stack_sizes = [si.item_stack_sizes[name] for name in ipairs items]
  -- p stack_sizes
  -- sinkable = [item for item in ipairs items when si\shouldSink item]
  -- p sinkable
  -- p si.item_stack_sizes['Plastic'] * si.item_container_sizes['Plastic']
  -- p si.item_counts['Plastic']

  -- for name, count in pairs si.item_counts
  --   if count == si.item_stack_sizes[name] * si.item_container_sizes[name]
  --     print "#{name} is full"

  configFile = buffer.create('r', filesystem.open '/etc/sinkcopd.json')
  config = json.decode(configFile\read 'a')
  configFile\close!

  si = autoSink config.site, config.container_classes
  print "sinkcopd: running every #{config.updateInterval} seconds"

  while true
    -- event.pull(config.updateInterval)
    sleep(config.updateInterval * 1000)
    si\updateSinkables!

    -- sleep(config.updateInterval * 1000)
    -- si\updateSinkables!
    coroutine.yield!
    computer.skip!
main!
