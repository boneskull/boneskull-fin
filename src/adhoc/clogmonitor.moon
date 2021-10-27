OUTPUT_RIGHT = 2
TIMEOUT = 0.0

splitter = component.proxy(component.findComponent 'goblinsink_splitter')[1]
alarm = component.proxy(component.findComponent 'goblinsink_alarm')[1]

main = () ->
  if not splitter\transferItem OUTPUT_RIGHT
    alarm\playSound 'beep'

  event.listen(splitter)

  while true
    evt = event.pull TIMEOUT
    if evt == 'ItemRequest'
      print 'itemrequest'
      if not splitter\transferItem OUTPUT_RIGHT
        alarm\playSound 'beep'
        -- TODO: notify remote network
      else
        alarm\stopSound!

main!
 