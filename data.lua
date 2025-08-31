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
local util = require("util")  -- deep copy

-- Helpers
local function hex_to_tint(hex) -- "#RRGGBB"
  local r = tonumber(hex:sub(2, 3), 16) / 255
  local g = tonumber(hex:sub(4, 5), 16) / 255
  local b = tonumber(hex:sub(6, 7), 16) / 255
  return { r = r, g = g, b = b, a = 1.0 }
end

local function lighten(c, amt)
  return { r = c.r + (1 - c.r) * amt,
           g = c.g + (1 - c.g) * amt,
           b = c.b + (1 - c.b) * amt,
           a = 1.0 }
end

local function darken(c, amt)
  local f = 1 - amt
  return { r = c.r * f, g = c.g * f, b = c.b * f, a = 1.0 }
end

local TAN = hex_to_tint("#FFD9C2")

-- Copy a graphical set and tint only base/center. Keep shadow untouched to avoid color bleed.
local function tinted_copy(gs, tint)
  local out = util.table.deepcopy(gs)
  if out.base   then out.base.tint   = tint end
  if out.center then out.center.tint = tint end
  -- DO NOT touch out.shadow
  return out
end

-- Tan button style by tinting the real stock button’s sets (shadow preserved)
styles["sp_list_button_tan"] = {
  type = "button_style",
  parent = "button",

  default_graphical_set  = tinted_copy(styles.button.default_graphical_set,  TAN),
  hovered_graphical_set  = tinted_copy(styles.button.hovered_graphical_set,  lighten(TAN, 0.10)),
  clicked_graphical_set  = tinted_copy(styles.button.clicked_graphical_set,  darken(TAN, 0.12)),
  disabled_graphical_set = tinted_copy(styles.button.disabled_graphical_set, darken(TAN, 0.20)),
}
