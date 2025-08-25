-- luacheck: globals script defines

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"

local function collect_platform_surfaces()
  local platforms = {}
  for _, surface in pairs(game.surfaces) do
    local ok_name, surface_name = pcall(function() return surface.name end)
    if ok_name and type(surface_name) == "string" and surface_name:find("^platform%-") then
      local caption = surface_name
      local log_message = "surface.name=" .. surface_name
      local ok_platform, platform = pcall(function() return surface.platform end)
      if ok_platform and platform then
        local ok_pname, p_name = pcall(function() return platform.name end)
        local ok_pindex, p_index = pcall(function() return platform.index end)
        local ok_force, p_force = pcall(function() return platform.force end)
        local force_name
        if ok_force and p_force then
          local ok_force_name, f_name = pcall(function() return p_force.name end)
          if ok_force_name and f_name then force_name = f_name end
        end
        if ok_pname and p_name then
          caption = p_name
        end
        log_message = log_message .. ", platform.name=" .. tostring(ok_pname and p_name or "nil") ..
                      ", platform.index=" .. tostring(ok_pindex and p_index or "nil") ..
                      ", platform.force=" .. tostring(force_name)
      else
        log_message = log_message .. ", platform=nil"
      end
      log(log_message)
      table.insert(platforms, {
        surface_name = surface_name,
        caption = caption,
        platform = ok_platform and platform or nil
      })
    end
  end
  return platforms
end

local function build_platform_ui(player)
  local frame = player.gui.screen.add{
    type = "frame",
    name = UI_NAME,
    caption = {"gui.space-platform-org-ui-title"},
    direction = "vertical"
  }
  frame.auto_center = true

  local platforms = collect_platform_surfaces()
  if #platforms == 0 then
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

  for _, entry in ipairs(platforms) do
    scroll.add{
      type = "button",
      name = BUTTON_PREFIX .. entry.surface_name,
      caption = entry.caption
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
    local surface_name = string.sub(element.name, #BUTTON_PREFIX + 1)
    local platforms = collect_platform_surfaces()
    local entry
    for _, data in ipairs(platforms) do
      if data.surface_name == surface_name then
        entry = data
        break
      end
    end
    local platform = entry and entry.platform
    if platform then
      pcall(function() player.opened = platform end)
      local ui = player.gui.screen[UI_NAME]
      if ui and ui.valid then ui.destroy() end
    end
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element
  if element and element.valid and element.name == UI_NAME then
    element.destroy()
  end
end)
