-- color-related utils
class RgbColor
  new: (r, g, b, a = 1.0) =>
    table.insert(@, r)
    table.insert(@, g)
    table.insert(@, b)
    table.insert(@, a)

  toFloat: =>
    {r, g, b, a} = @
    r = r / 255.0
    g = g / 255.0
    b = b / 255.0
    a = a
    {r, g, b, a}

rgb_colors = {
  white: {255, 255, 255},
  black: {0, 0, 0},
  red: {255, 0, 0},
  green: {0, 255, 0},
  blue: {0, 0, 255},
  yellow: {255, 255, 0},
  cyan: {0, 255, 255},
  magenta: {255, 0, 255}
}

colors = {name, RgbColor(color[1], color[2], color[3], color[4]) for name, color in pairs rgb_colors}

{
  RgbColor: RgbColor
  colors: colors
}
