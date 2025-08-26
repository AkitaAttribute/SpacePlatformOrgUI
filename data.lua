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

-- GUI styles
local styles = data.raw["gui-style"].default

-- Alternating list-row button: tan background
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

-- Small, text-friendly colored tool buttons for header +/- controls
styles["sp_tool_button_green"] = {
  type = "button_style",
  parent = "tool_button",
  default_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.45, g = 0.76, b = 0.45, a = 1.0} }
  },
  hovered_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.52, g = 0.84, b = 0.52, a = 1.0} }
  },
  clicked_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.39, g = 0.66, b = 0.39, a = 1.0} }
  },
  disabled_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.34, g = 0.58, b = 0.34, a = 1.0} }
  }
}

styles["sp_tool_button_red"] = {
  type = "button_style",
  parent = "tool_button",
  default_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.80, g = 0.35, b = 0.35, a = 1.0} }
  },
  hovered_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.88, g = 0.42, b = 0.42, a = 1.0} }
  },
  clicked_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.70, g = 0.30, b = 0.30, a = 1.0} }
  },
  disabled_graphical_set = {
    base = { position = {0, 0}, corner_size = 8, tint = {r = 0.55, g = 0.25, b = 0.25, a = 1.0} }
  }
}
