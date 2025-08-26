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

-- Requested base colors (exact)
local TAN_HEX   = "#D2B48C"
local GREEN_HEX = "#00ab66"
local RED_HEX   = "#cf142b"

local TAN   = hex_to_tint(TAN_HEX)
local GREEN = hex_to_tint(GREEN_HEX)
local RED   = hex_to_tint(RED_HEX)

-- Alternating list-row button: tan background (slightly brighter on hover)
styles["sp_list_button_tan"] = {
  type = "button_style",
  parent = "button",
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = TAN } },
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = lighten(TAN, 0.18) } },
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = darken(TAN, 0.10) } },
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = darken(TAN, 0.20) } },
}

-- Base header tool button with fixed paddings/height to guarantee alignment
styles["sp_hdr_tool_button"] = {
  type = "button_style",
  parent = "tool_button",
  top_padding = 1, bottom_padding = 1, left_padding = 6, right_padding = 6,
  minimal_height = 26, maximal_height = 26,
  default_font_color = {1, 1, 1, 1},
  hovered_font_color = {1, 1, 1, 1},
  clicked_font_color = {1, 1, 1, 1},
}

-- Green/Red variants using your hex colors (lighter on hover)
styles["sp_tool_button_green"] = {
  type = "button_style",
  parent = "sp_hdr_tool_button",
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = GREEN } },
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = lighten(GREEN, 0.22) } },
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = darken(GREEN, 0.10) } },
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = darken(GREEN, 0.30) } },
}

styles["sp_tool_button_red"] = {
  type = "button_style",
  parent = "sp_hdr_tool_button",
  default_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = RED } },
  hovered_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = lighten(RED, 0.22) } },
  clicked_graphical_set  = { base = { position = {0, 0}, corner_size = 8, tint = darken(RED, 0.10) } },
  disabled_graphical_set = { base = { position = {0, 0}, corner_size = 8, tint = darken(RED, 0.30) } },
}
