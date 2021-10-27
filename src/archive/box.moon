require('convert')

export Styles = {
  Single: {
    '┌', '┐', '└', '┘', '─', '│'
  },
  Double: {
    '╔', '╗', '╚', '╝', '═', '║'
  }
}

ELLIPSIS = '…'

export Colors = {
  White: {255, 255, 255, 1},
  Black: {0, 0, 0, 0},
  Red: {255, 0, 0, 1},
  Green: {0, 255, 0, 1},
  Blue: {0, 0, 255, 1},
  Yellow: {255, 255, 0, 1},
  Orange: {255, 165, 0, 1},
  Gray: {48, 48, 48, 1}
}


export box = (gpu) ->
  maxWidth, maxHeight = gpu\getSize!

  (
    text, 
    x = 0,
    y = 0,
    w = maxWidth,
    h = maxHeight,
    paddingLeft = 4,
    paddingTop = 1,
    boxFg = Colors.Gray,
    boxBg = Colors.Black,
    textFg = Colors.White,
    textBg = Colors.Black,
    style = Styles.Single
  ) ->
    
    if type(style) == 'string' and not Styles[style]
      error('unknown style', style)
    
    {topLeft, topRight, bottomLeft, bottomRight, horizontal, vertical} = style
    
    boxFg = rgbToFloats boxFg  
    boxBg = rgbToFloats boxBg
    textFg = rgbToFloats textFg
    textBg = rgbToFloats textBg

    buf = gpu\getBuffer!
    buf\setSize w, h
    buf\fill 0, 0, w, h, " "
    -- top left
    buf\setText x, y, topLeft, boxFg, boxBg

    -- top line
    for x1 = x + 1, w-2
      buf\setText x1, y, horizontal, boxFg, boxBg
    
    -- top right
    buf\setText w-1, y, topRight, boxFg, boxBg
    
    -- sides
    for y1 = y+1, h - 2
      buf\setText x, y1, vertical, boxFg, boxBg
      buf\setText w-1, y1, vertical, boxFg, boxBg

    -- bottom left
    buf\setText x, h-1, bottomLeft, boxFg, boxBg

    -- bottom line
    for x1 = x + 1, w-2
      buf\setText x1, h-1, horizontal, boxFg, boxBg
    
    -- bottom right
    buf\setText w-1, h-1, bottomRight, boxFg, boxBg

    
    textX = x + paddingLeft
    maxTextWidth = w - paddingLeft - textX
    textY = y + paddingTop
    maxTextHeight = h - paddingTop - textY
      
    lines = [s for s in text\gmatch '[^\r?\n]+']

    for row = 1, math.min #lines, maxTextHeight
      line = lines[row]
      if #line > maxTextWidth
        line = string.sub 1, maxTextWidth - 2 .. ELLIPSIS
      buf\setText textX, row + textY, line, textFg, textBg
  
    gpu\setBuffer buf
    gpu\flush!

export test_box = () ->
  gpu = computer.getPCIDevices(findClass "GPUT1")[1]
  screen = computer.getPCIDevices(findClass "FINComputerScreen")[1]
  gpu\bindScreen screen
  gpu\setBackground 0, 0, 0, 0
  gpu\fill 0, 0, 120, 30, ' '
  gpu\flush!
  -- gpu\setForeground 1, 1, 1, 1
  doBox = box gpu
  doBox 'hurble duh'

