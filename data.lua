-- data.lua

data:extend({
  {
    type = "custom-input",
    name = "space-platform-org-ui-toggle",
    key_sequence = "",
    consuming = "none"
  }
})

local styles = data.raw["gui-style"].default

-- Helpers
local function hex_to_tint(hex)
  local r = tonumber(hex:sub(2, 3), 16) / 255
  local g = tonumber(hex:sub(4, 5), 16) / 255
  local b = tonumber(hex:sub(6, 7), 16) / 255
  return { r = r, g = g, b = b, a = 1.0 }
end
local function lighten(c, amt) -- mix towards white (0..1)
  return { r = c.r + (1 - c.r) * amt,
           g = c.g + (1 - c.g) * amt,
           b = c.b + (1 - c.b) * amt,
           a = 1.0 }
end

-- Very pale tan target (#FFD9C2), pushed even lighter to overcome the dark base
local TAN_BASE = hex_to_tint("#FFD9C2")

styles["sp_list_button_tan"] = {
  type = "button_style",
  parent = "button",

  -- Make the base nearly white-with-tan to read clearly
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = lighten(TAN_BASE, 0.55) } },
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = lighten(TAN_BASE, 0.72) } },
  -- Slightly darker than base when pressed, but still light
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = lighten(TAN_BASE, 0.40) } },
  -- Disabled is a touch darker than base
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = lighten(TAN_BASE, 0.30) } },
}
