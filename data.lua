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

-- Helpers
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

-- Requested colors
local TAN   = hex_to_tint("#D2B48C")
local GREEN = hex_to_tint("#00ab66")
local RED   = hex_to_tint("#cf142b")

-- Alternating list-row button: tan background
styles["sp_list_button_tan"] = {
  type = "button_style",
  parent = "button",
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = TAN } },
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(TAN, 1.15) } },
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(TAN, 0.90) } },
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = scale(TAN, 0.80) } },
}

-- Compact, text-friendly colored tool buttons for header +/- controls
-- Force identical paddings and height here so red/green match exactly.
styles["sp_tool_button_green"] = {
  type = "button_style",
  parent = "tool_button",
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = GREEN } },
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(GREEN, 1.20) } },
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(GREEN, 0.90) } },
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = scale(GREEN, 0.70) } },
  default_font_color     = {1, 1, 1, 1},
  hovered_font_color     = {1, 1, 1, 1},
  clicked_font_color     = {1, 1, 1, 1},
  top_padding = 1, bottom_padding = 1, left_padding = 6, right_padding = 6,
  minimal_height = 24, maximal_height = 24
}

styles["sp_tool_button_red"] = {
  type = "button_style",
  parent = "tool_button",
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = RED } },
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(RED, 1.20) } },
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = scale(RED, 0.90) } },
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = scale(RED, 0.70) } },
  default_font_color     = {1, 1, 1, 1},
  hovered_font_color     = {1, 1, 1, 1},
  clicked_font_color     = {1, 1, 1, 1},
  top_padding = 1, bottom_padding = 1, left_padding = 6, right_padding = 6,
  minimal_height = 24, maximal_height = 24
}
