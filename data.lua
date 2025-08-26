-- data.lua

-- Existing custom input
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

-- Tiny helpers for color work
local function hex_to_tint(hex) -- "#RRGGBB"
  local r = tonumber(hex:sub(2, 3), 16) / 255
  local g = tonumber(hex:sub(4, 5), 16) / 255
  local b = tonumber(hex:sub(6, 7), 16) / 255
  return { r = r, g = g, b = b, a = 1.0 }
end
local function scale(c, f)
  local function s(x) return math.min(1, math.max(0, x * f)) end
  return { r = s(c.r), g = s(c.g), b = s(c.b), a = 1.0 }
end

-- Colors (from your request)
local TAN   = hex_to_tint("#D2B48C")
local GREEN = hex_to_tint("#00ab66")
local RED   = hex_to_tint("#cf142b")

-- Alternating list-row button: tan background
styles["sp_list_button_tan"] = {
  type = "button_style",
  parent = "button",
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = TAN } },
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(TAN, 1.08) } },
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(TAN, 0.92) } },
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = scale(TAN, 0.85) } },
}

-- Compact, text-friendly colored tool buttons for header +/- controls
styles["sp_tool_button_green"] = {
  type = "button_style",
  parent = "tool_button",
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = GREEN } },
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(GREEN, 1.10) } },
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(GREEN, 0.92) } },
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = scale(GREEN, 0.75) } },
}

styles["sp_tool_button_red"] = {
  type = "button_style",
  parent = "tool_button",
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = RED } },
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(RED, 1.10) } },
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(RED, 0.92) } },
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = scale(RED, 0.75) } },
}
