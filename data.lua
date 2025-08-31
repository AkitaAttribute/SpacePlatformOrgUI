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
-- We only keep a single style for alternating list rows (tan).
local styles = data.raw["gui-style"].default

-- Small helpers for color math
local function hex_to_tint(hex) -- "#RRGGBB"
  local r = tonumber(hex:sub(2, 3), 16) / 255
  local g = tonumber(hex:sub(4, 5), 16) / 255
  local b = tonumber(hex:sub(6, 7), 16) / 255
  return { r = r, g = g, b = b, a = 1.0 }
end
local function lighten(c, amt) -- towards white
  return { r = c.r + (1 - c.r) * amt,
           g = c.g + (1 - c.g) * amt,
           b = c.b + (1 - c.b) * amt,
           a = 1.0 }
end
local function darken(c, amt) -- towards black
  local f = 1 - amt
  return { r = c.r * f, g = c.g * f, b = c.b * f, a = 1.0 }
end

-- Tan for alternating rows (#D2B48C)
local TAN = hex_to_tint("#D2B48C")

styles["sp_list_button_tan"] = {
  type = "button_style",
  parent = "button",
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = TAN } },
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = lighten(TAN, 0.18) } },
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = darken(TAN, 0.12) } },
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = darken(TAN, 0.22) } },
}
