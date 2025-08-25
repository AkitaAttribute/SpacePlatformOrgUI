-- luacheck: globals script defines log serpent global

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"
local SIZE_INC   = 40
local HEADER_DEC = "sp-ui-size-dec"
local HEADER_INC = "sp-ui-size-inc"

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

  local header = frame.add{ type="flow", direction="horizontal", name="sp_header" }
  header.add{ type="label", caption={"gui.space-platforms-org-ui-title"}, style="frame_title" }
  header.add{ type="empty-widget", style="draggable_space_header" }.style.horizontally_stretchable = true
  header.add{
    type="sprite-button",
    name=HEADER_DEC,
    sprite="utility/arrow-left",
    tooltip="Narrower",
    style="frame_action_button"
  }
  header.add{
    type="sprite-button",
    name=HEADER_INC,
    sprite="utility/arrow-right",
    tooltip="Wider",
    style="frame_action_button"
  }

  -- Collect platforms from the force
  local entries, platforms = collect_platforms(player.force)  -- sequential array of {id, caption}
  st.platforms = platforms
  log("UI: rendering " .. tostring(#entries) .. " platforms")

  -- Scroll pane + vertical list container
  local scroll = frame.add{ type = "scroll-pane", name = "platform_scroll" }
  scroll.style.vertically_stretchable   = true
  scroll.style.horizontally_stretchable = true
  scroll.style.minimal_width  = st.w - 20
  scroll.style.minimal_height = st.h - 60

  local list = scroll.add{ type = "flow", name = "platform_list", direction = "vertical" }
  list.style.vertically_stretchable   = true
  list.style.horizontally_stretchable = true

  if #entries == 0 then
    list.add{ type = "label", caption = {"gui.space-platforms-org-ui-no-platforms"} }
    return
  end

  for _, entry in ipairs(entries) do
    local b = list.add{
      type = "button",
      name = BUTTON_PREFIX .. entry.id,
      caption = entry.caption,
      tags = { platform_index = entry.id }
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

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  local player  = game.get_player(event.player_index)
  if not (element and element.valid and player) then return end
  local st = ui_state(player.index)

  if element.name == HEADER_DEC or element.name == HEADER_INC then
    local delta = (element.name == HEADER_INC) and SIZE_INC or -SIZE_INC
    st.w = math.max(300, math.min(900, st.w + delta))
    local existing = player.gui.screen[UI_NAME]
    if existing and existing.valid then existing.destroy() end
    build_platform_ui(player)
    return
  end

  -- Guard: respond only to our buttons
  if not element.name or element.name:sub(1, #BUTTON_PREFIX) ~= BUTTON_PREFIX then return end

  -- Prefer tags over parsing
  local pid = element.tags and element.tags.platform_index
  if not pid then
    pid = tonumber(element.name:sub(#BUTTON_PREFIX + 1))
  end
  if not pid then
    log("UI click: no platform id on " .. element.name)
    return
  end

  -- Resolve platform
  local plat = st.platforms[pid]
  if not (plat and plat.valid) then
    log("UI click: platform not found for id=" .. tostring(pid))
    return
  end

  -- Resolve surface and a safe position (avoid blocked {0,0})
  local surf = plat.surface
  if not (surf and surf.valid) then
    log("UI click: missing/invalid surface for id=" .. tostring(pid))
    return
  end
  local pos = surf.find_non_colliding_position("character", {x=0, y=0}, 64, 1) or {x=0, y=0}

  -- Try map view, then zoom fallback (both protected)
  local ok = pcall(function()
    player.open_map{ position = pos, surface = surf, scale = 1 }
  end)
  if not ok then
    pcall(function()
      player.zoom_to_world(pos, 0.5, surf)
    end)
  end

  -- Temporary trace (remove after verifying)
  log("UI click: opened platform " .. tostring(pid) ..
      " on surface=" .. tostring(surf.name) .. " at " .. serpent.line(pos))
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element
  if element and element.valid and element.name == UI_NAME then
    element.destroy()
  end
end)
