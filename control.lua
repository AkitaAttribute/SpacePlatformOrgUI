-- luacheck: globals script defines log serpent global

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"

local function ui_state(pi)
  global.spui = global.spui or {}
  local st = global.spui[pi]
  if not st then
    st = { w = 440, h = 520, platforms = {} }
    global.spui[pi] = st
  end
  return st
end

local function collect_platforms(force)
  local entries, platforms = {}, {}
  if not (force and force.valid and force.platforms) then return entries, platforms end
  for _, p in pairs(force.platforms) do
    if p and p.valid then
      entries[#entries + 1] = { id = p.index, caption = p.name or ("Platform " .. tostring(p.index)) }
      platforms[p.index] = p
    end
  end
  return entries, platforms
end

local function build_platform_ui(player)
  local frame = player.gui.screen.add{
    type = "frame",
    name = UI_NAME,
    direction = "vertical"
  }
  frame.auto_center = true

  local st = ui_state(player.index)

  frame.style.minimal_width  = st.w
  frame.style.minimal_height = st.h

  local header = frame.add{ type = "flow", direction = "horizontal", name = "sp_header" }
  header.add{ type = "label", caption = {"gui.space-platforms-org-ui-title"}, style = "frame_title" }
  header.add{ type = "empty-widget", style = "draggable_space_header" }.style.horizontally_stretchable = true
  header.add{
    type = "sprite-button",
    name = "sp-size-w-dec",
    sprite = "utility/arrow-left",
    tooltip = "Narrower",
    style = "frame_action_button",
  }
  header.add{
    type = "sprite-button",
    name = "sp-size-w-inc",
    sprite = "utility/arrow-right",
    tooltip = "Wider",
    style = "frame_action_button",
  }
  header.add{
    type = "sprite-button",
    name = "sp-size-h-dec",
    sprite = "utility/arrow-up",
    tooltip = "Shorter",
    style = "frame_action_button",
  }
  header.add{
    type = "sprite-button",
    name = "sp-size-h-inc",
    sprite = "utility/arrow-down",
    tooltip = "Taller",
    style = "frame_action_button",
  }

  -- Collect platforms from the force
  local entries, platforms = collect_platforms(player.force)  -- sequential array of {id, caption}
  st.platforms = platforms
  log("UI: rendering " .. tostring(#entries) .. " platforms")

  -- Scroll pane + vertical list container
  local scroll = frame.add{ type = "scroll-pane", name = "platform_scroll" }
  scroll.style.vertically_stretchable   = true
  scroll.style.horizontally_stretchable = true

  local list = scroll.add{ type = "flow", name = "platform_list", direction = "vertical" }
  list.style.vertically_stretchable   = true
  list.style.horizontally_stretchable = true

  if #entries == 0 then
    list.add{ type = "label", caption = {"gui.space-platforms-org-ui-no-platforms"} }
    return
  end

  for _, entry in ipairs(entries) do
    local idx = entry.platform_index or entry.platform_id or (entry.platform and entry.platform.index) or entry.id
    local b = list.add{
      type = "button",
      name = BUTTON_PREFIX .. tostring(idx),
      caption = entry.caption or entry.surface_name,
      tags = { platform_index = idx }
    }
    if b and b.valid then
      b.style.horizontally_stretchable = true
      b.style.minimal_width  = 260
      b.style.maximal_width  = 320
      b.style.minimal_height = 24
      b.style.top_padding    = 2
      b.style.bottom_padding = 2
    end
  end
end

local function rebuild_ui(player)
  local existing = player.gui.screen[UI_NAME]
  if existing and existing.valid then existing.destroy() end
  build_platform_ui(player)
end

local function toggle_platform_ui(player)
  local existing = player.gui.screen[UI_NAME]
  if existing and existing.valid then
    existing.destroy()
  else
    build_platform_ui(player)
  end
end

script.on_init(function() global.spui = global.spui or {} end)
script.on_configuration_changed(function() global.spui = global.spui or {} end)

script.on_event("space-platform-org-ui-toggle", function(event)
  local player = game.get_player(event.player_index)
  if player then
    toggle_platform_ui(player)
  end
end)

local function open_platform_view(player, pid)
  if not pid then return end
  local plat
  if player.force and player.force.valid and player.force.platforms then
    for _, p in pairs(player.force.platforms) do
      if p.index == pid then plat = p; break end
    end
  end
  if not (plat and plat.valid) then
    player.print("Platform not found.")
    return
  end
  local surf = plat.surface
  if not (surf and surf.valid) then
    player.print("Platform surface unavailable.")
    return
  end
  local pos = plat.position or {0,0}
  local safe = surf.find_non_colliding_position("character", pos, 64, 1) or pos
  local ok = pcall(function()
    player.set_controller{
      type = defines.controllers.remote,
      surface = surf,
      position = safe,
      start_zoom = 0.7,
    }
  end)
  if not ok then
    pcall(function() player.zoom_to_world(safe, 0.5, surf) end)
  end
end

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  local player  = game.get_player(event.player_index)
  if not (element and element.valid and player) then return end
  local st = ui_state(player.index)

  if element.name == "sp-size-w-dec" then st.w = math.max(320, (st.w or 440) - 40); rebuild_ui(player); return end
  if element.name == "sp-size-w-inc" then st.w = (st.w or 440) + 40; rebuild_ui(player); return end
  if element.name == "sp-size-h-dec" then st.h = math.max(320, (st.h or 520) - 40); rebuild_ui(player); return end
  if element.name == "sp-size-h-inc" then st.h = (st.h or 520) + 40; rebuild_ui(player); return end

  if not element.name or element.name:sub(1, #BUTTON_PREFIX) ~= BUTTON_PREFIX then return end

  local pid = element.tags and element.tags.platform_index
  if pid then open_platform_view(player, pid); return end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element
  if element and element.valid and element.name == UI_NAME then
    element.destroy()
  end
end)
