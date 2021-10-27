export rgbToHsv = (color = {0, 0, 0, 0}) ->
  {r, g, b, alpha} = color

  r /= 255
  g /= 255
  b /= 255
  
  max = math.max r, g, b
  min = math.min r, g, b
  value = max
  delta = max - min
  saturation = if max == 0 then 0 else delta / max

  hue = if max == min
    0
  elseif max == r 
    (g - b) / delta + (if g < b then 6 else 0)
  elseif max == g 
    (b - r) / delta + 2
  else
    (r - g) / delta + 4
  
  hue *= 60
  saturation *= 100
  value *= 100

  {hue, saturation, value, alpha}

    
export rgbToFloats = (color = {0, 0, 0, 0}) ->
  {r, g, b, alpha} = color
  
  r /= 255.0
  g /= 255.0
  b /= 255.0

  {r, g, b, alpha}

export getGpu = () -> computer.getPCIDevices(findClass "GPUT1")[1]

export getLocalScreen = () -> computer.getPCIDevices(findClass "FINComputerScreen")[1]

export dump = (value) ->
  seen = {}
  _dump = (what, depth=0) ->
    t = type what
    if t == "string"
			'"'..what..'"\n'
    elseif t == "table"
      if seen[what]
        return "recursion("..tostring(what) ..")...\n"
      seen[what] = true

      depth += 1
      lines = for k,v in pairs what
        (" ")\rep(depth*4).."["..tostring(k).."] = ".._dump(v, depth)

      seen[what] = false

      class_name = if what.__class
        "<#{what.__class.__name}>"

      "#{class_name or ""}{\n" .. table.concat(lines) .. (" ")\rep((depth - 1)*4) .. "}\n"
    else
      tostring(what).."\n"

  _dump value

export p = (...) -> print dump ...

