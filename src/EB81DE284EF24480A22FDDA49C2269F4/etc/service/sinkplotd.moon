{:Plotter} = require 'plotter'

main = () ->
  network = computer.getPCIDevices(findClass("NetworkCard"))[1]
  network\open 0
  
  plotter = Plotter! -- 'goblin-display-sinkinfo'
  while true
    event.pull 0.05
    plotter\addPeriod(math.random plotter.h)
    
main!
