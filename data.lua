-- data.lua

-- Existing custom input (unchanged)
data:extend({
  {
    type = "custom-input",
    name = "space-platform-org-ui-toggle",
    key_sequence = "",
    consuming = "none"
  }
})

-- ===== Styles =====
local styles = data.raw["gui-style"].default

-- Color helpers
local function hex_to_tint(hex) -- "#RRGGBB"
  local r = tonumber(hex:sub(2, 3), 16) / 255
  local g = tonumber(hex:sub(4, 5), 16) / 255
  local b = tonumber(hex:sub(6, 7), 16) / 255
  return { r = r, g = g, b = b, a = 1.0 }
end

local function lighten(c, amt) -- mix towards white by amt (0..1)
  return { r = c.r + (1 - c.r) * amt,
           g = c.g + (1 - c.g) * amt,
           b = c.b + (1 - c.b) * amt,
           a = 1.0 }
end

local function darken(c, amt) -- scale towards black by amt (0..1)
  local f = 1 - amt
  return { r = c.r * f, g = c.g * f, b = c.b * f, a = 1.0 }
end

-- Very pale tan for alternating rows (#FFD9C2)
local TAN = hex_to_tint("#FFD9C2")

styles["sp_list_button_tan"] = {
  type = "button_style",
  parent = "button",
  -- base color
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = TAN } },
  -- slight lift on hover so it still reads as interactive even on a pale base
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = lighten(TAN, 0.10) } },
  -- gentle press state
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = darken(TAN, 0.12) } },
  -- disabled a bit dimmer
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = darken(TAN, 0.22) } },
}
