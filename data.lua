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

-- GUI styles: define a tan variant for alternating list-row buttons.
-- Background color must be provided by a style at data stage.
local styles = data.raw["gui-style"].default

styles["sp_list_button_tan"] = {
  type = "button_style",
  parent = "button",
  default_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.88, g = 0.80, b = 0.62, a = 1.0} }
  },
  hovered_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.92, g = 0.84, b = 0.66, a = 1.0} }
  },
  clicked_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.84, g = 0.76, b = 0.58, a = 1.0} }
  },
  disabled_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.78, g = 0.72, b = 0.56, a = 1.0} }
  }
}
