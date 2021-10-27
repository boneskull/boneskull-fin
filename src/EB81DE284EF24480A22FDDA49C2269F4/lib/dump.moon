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

