DIRECTION_IN = 0
CONVEYOR_TYPE = 0

void = component.proxy(component.findComponent 'void')[1]

isFull = () ->
  inv = void\getInventories![1]
  for i = 0, inv.size - 1
    stack = inv\getStack i
    if not stack or stack.count == 0
      return false
  true

flush= () -> 
  void\getInventories![1]\flush!
  print 'FLUSHED'


local connection
for _, conn in ipairs void\getFactoryConnectors!
  if conn.isConnected and conn.direction == DIRECTION_IN and conn.type == CONVEYOR_TYPE 
    connection = conn
    break

if not connection then computer.panic('could not find suitable factory connection')

event.listen(connection)

while true do
  event.pull(30.0)
  if isFull! then
    flush!

  