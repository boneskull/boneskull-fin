{:colors} = require 'color'
require 'dump'

class Plotter
  new: (screen, gpu, bg_color = colors.black, fg_color = colors.white) =>    
    if not gpu
      gpu = computer.getPCIDevices(findClass 'GPUT1')[1]
      if not gpu then error 'No GPU found!'
    if not screen
      screen = computer.getPCIDevices(findClass 'FINComputerScreen')[1]
      print "Found screen module with id #{screen}"      
      if not screen
        screen = component.findComponent(findClass 'Screen')[1]
        if not screen then error 'No screen found!'
        gpu\bindScreen(component.proxy screen)
        print 'Found external screen'
      else
        gpu\bindScreen screen
    elseif type screen == 'string'
      id = screen
      screen = component.findComponent(id)[1]
      if not screen then error "Could not find screen with nick/id #{id}"
      print "Found screen with id #{id}"
      gpu\bindScreen(component.proxy screen)
        
    @gpu = gpu
    @bg_color = bg_color
    @fg_color = fg_color
    @period = 0
    @lastValue = 0
    @w, @h = gpu\getSize!
    @clear!
    @gpu\flush!
  
  clear: =>
    {r, g, b, a} = @bg_color
    @gpu\setBackground r, g, b, a
    @gpu\fill 0, 0, @w, @h, ' '
    {r, g, b, a} = @fg_color
    @gpu\setBackground r, g, b, a
  
  addPeriod: (value) =>
    @clear!
    
    for i = 0, @w - 1
      x = (@period + i) / 10.0
      x1 = math.floor x
      x2 = x1 + 1
      y1 = @lastValue
      y2 = value
      delta = y1 + ((x - x1) * ((y2 - y1) / (x2 - x1)))
      delta = math.floor delta
      @gpu\setText i, delta, ' '
    
    @lastValue = value    
    @period = @period + 1
    @gpu\flush!
    

return {Plotter: Plotter}
