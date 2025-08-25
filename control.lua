-- luacheck: globals remote serpent

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"

local function get_space_platforms(force)
  if not (force and force.valid) then return nil end
  local platforms = {}
  -- Derive platforms by inspecting available surfaces.
  for _, surface in pairs(game.surfaces) do
    local ok, platform = pcall(function() return surface.platform end)
    if ok and platform and platform.valid and platform.force == force then
      platforms[platform.index] = platform
    end
  end
  if next(platforms) then return platforms end
  return nil
end

local function print_remote_interfaces(player)
  for name, interface in pairs(remote.interfaces) do
    player.print("Remote interface '" .. name .. "':")
    for func_name, func in pairs(interface) do
      if type(func) == "function" then
        player.print("  " .. func_name)
      end
    end
  end
end

local function print_platform_surfaces(player)
  player.print("Surfaces starting with 'platform-':")
  local found = false
  for _, surface in pairs(game.surfaces) do
    local ok_name, surface_name = pcall(function() return surface.name end)
    if ok_name and type(surface_name) == "string" and surface_name:find("^platform%-") then
      found = true
      player.print("  " .. surface_name)
      local ok_fields, fields = pcall(function()
        local t = {}
        for k, v in pairs(surface) do
          if type(v) ~= "function" then t[k] = v end
        end
        return t
      end)
      if ok_fields and fields then
        local had = false
        for k, v in pairs(fields) do
          had = true
          local value_str
          if type(v) == "table" then
            local ok_serp, serp_str = pcall(function() return serpent.line(v, {comment = false}) end)
            value_str = ok_serp and serp_str or "[table]"
          else
            local ok_tostr, s = pcall(tostring, v)
            value_str = ok_tostr and s or "[unprintable]"
          end
          player.print("    " .. k .. ": " .. value_str)
        end
        if not had then
          player.print("    (no non-function fields)")
        end
      else
        player.print("    (unable to read fields)")
      end
    end
  end
  if not found then
    player.print("  (none)")
  end
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

  for _, platform in pairs(platforms) do
    local caption = platform.name or ("Platform " .. (platform.index or _))
    scroll.add{
      type = "button",
      name = BUTTON_PREFIX .. tostring(platform.index or _),
      caption = caption
    }
  end
end

local function toggle_platform_ui(player)
  local existing = player.gui.screen[UI_NAME]
  if existing and existing.valid then
    existing.destroy()
  else
    print_remote_interfaces(player)
    print_platform_surfaces(player)
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
      local platform = platforms[id]
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
