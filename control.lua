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
  local function print_log(msg)
    player.print(msg)
    log(msg)
  end

  local function inspect_table(tbl, prefix, depth)
    depth = depth or 1
    if depth > 2 then return end
    local ok_keys, keys = pcall(function()
      local ks = {}
      for k in pairs(tbl) do
        ks[#ks + 1] = k
      end
      return ks
    end)
    if not ok_keys then
      print_log(prefix .. "(unable to iterate table)")
      return
    end
    for _, k in ipairs(keys) do
      local ok_val, v = pcall(function() return tbl[k] end)
      local key_str = tostring(k)
      if not ok_val then
        print_log(prefix .. key_str .. ": [error reading]")
      else
        local t = type(v)
        if t == "string" or t == "number" or t == "boolean" then
          local ok_tostr, vstr = pcall(tostring, v)
          print_log(prefix .. key_str .. ": " .. (ok_tostr and vstr or "[unprintable]"))
        elseif t == "table" then
          print_log(prefix .. key_str .. ": [table]")
          inspect_table(v, prefix .. "  ", depth + 1)
        elseif t ~= "function" then
          print_log(prefix .. key_str .. ": [" .. t .. "]")
        end
      end
    end
  end

  print_log("Surfaces starting with 'platform-':")
  local found = false
  for _, surface in pairs(game.surfaces) do
    local ok_name, surface_name = pcall(function() return surface.name end)
    if ok_name and type(surface_name) == "string" and surface_name:find("^platform%-") then
      found = true
      print_log("  " .. surface_name)
      inspect_table(surface, "    ", 1)
    end
  end
  if not found then
    print_log("  (none)")
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
