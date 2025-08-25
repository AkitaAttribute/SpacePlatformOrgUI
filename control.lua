-- luacheck: globals script defines

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"

local function get_space_platforms(force)
  if not (force and force.valid) then return nil end
  local platforms = {}
  -- Derive platforms by inspecting available surfaces whose names start with 'platform-'.
  for _, surface in pairs(game.surfaces) do
    local ok_name, surface_name = pcall(function() return surface.name end)
    if ok_name and type(surface_name) == "string" and surface_name:find("^platform%-") then
      local ok_platform, platform = pcall(function() return surface.platform end)
      if ok_platform and platform and platform.valid and platform.force == force then
        platforms[platform.index] = {platform = platform, surface_name = surface_name}
      end
    end
  end
  if next(platforms) then return platforms end
  return nil
end

local function build_platform_ui(player)
  local frame = player.gui.screen.add{
    type = "frame",
    name = UI_NAME,
    caption = {"gui.space-platform-org-ui-title"},
    direction = "vertical"
  }
  frame.auto_center = true

  local platforms = get_space_platforms(player.force)
  if not (platforms and next(platforms)) then
    frame.add{
      type = "label",
      caption = {"gui.space-platform-org-ui-no-platforms"}
    }
    return
  end

  local scroll = frame.add{
    type = "scroll-pane",
    name = "platform_scroll"
  }
  scroll.style.maximal_height = 400
  scroll.style.minimal_width = 250
  scroll.style.vertically_stretchable = true
  scroll.style.horizontally_stretchable = true

  for _, data in pairs(platforms) do
    local platform = data.platform
    local caption = (platform and platform.name) or data.surface_name
    scroll.add{
      type = "button",
      name = BUTTON_PREFIX .. tostring(platform and platform.index),
      caption = caption
    }
  end
end

local function toggle_platform_ui(player)
  local existing = player.gui.screen[UI_NAME]
  if existing and existing.valid then
    existing.destroy()
  else
    build_platform_ui(player)
  end
end

script.on_event("space-platform-org-ui-toggle", function(event)
  local player = game.get_player(event.player_index)
  if player then
    toggle_platform_ui(player)
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  local player = game.get_player(event.player_index)
  if not (element and element.valid and player) then return end

  if string.sub(element.name, 1, #BUTTON_PREFIX) == BUTTON_PREFIX then
    local id = tonumber(string.sub(element.name, #BUTTON_PREFIX + 1))
    local platforms = get_space_platforms(player.force)
    if id and platforms then
      local entry = platforms[id]
      local platform = entry and entry.platform
      if platform then
        player.opened = platform
        local ui = player.gui.screen[UI_NAME]
        if ui and ui.valid then ui.destroy() end
      end
    end
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element
  if element and element.valid and element.name == UI_NAME then
    element.destroy()
  end
end)
