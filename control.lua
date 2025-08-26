-- luacheck: globals global script defines log serpent

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"

-- Header (window-size) button ids
local HEADER_W_DEC = "sp-size-w-dec"
local HEADER_W_INC = "sp-size-w-inc"
local HEADER_H_DEC = "sp-size-h-dec"
local HEADER_H_INC = "sp-size-h-inc"

-- Return the engine 'global' table safely, creating it if needed.
local function get_global()
  local g = rawget(_G, "global")
  if type(g) ~= "table" then
    g = {}
    rawset(_G, "global", g)
  end
  return g
end

local function ui_state(pi)
  local g = get_global()
  g.spui = g.spui or {}
  local st = g.spui[pi]
  if not st then
    -- w/h = window size; button_w/h = list row size (kept for future use)
    st = { w = 440, h = 528, loc = nil, scroll = 0, button_w = 260, button_h = 24 }
    g.spui[pi] = st
  end
  return st
end

-- Returns st (ui_state) and captures the current frame+scroll into it.
local function capture_ui_state(player)
  local st = ui_state(player.index)
  local frame = player.gui.screen[UI_NAME]
  if frame and frame.valid then
    -- size
    st.w = tonumber(frame.style.minimal_width) or st.w
    st.h = tonumber(frame.style.minimal_height) or st.h
    -- position
    local loc = frame.location
    if loc and loc.x and loc.y then
      st.loc = { x = loc.x, y = loc.y }
    end
    -- scroll
    local scroll = frame["platform_scroll"]
    if scroll and scroll.valid then
      local sb = scroll.vertical_scrollbar
      if sb and sb.valid then
        st.scroll = tonumber(sb.value) or st.scroll or 0
      end
    end
  end
  return st
end

-- Applies st (ui_state) to the newly built frame.
local function apply_ui_state(player)
  local st = ui_state(player.index)
  local frame = player.gui.screen[UI_NAME]
  if not (frame and frame.valid) then return end

  -- size first so location restore uses final frame dimensions
  if st.w then frame.style.minimal_width  = st.w end
  if st.h then frame.style.minimal_height = st.h end

  if st.loc and st.loc.x and st.loc.y then
    frame.location = { x = st.loc.x, y = st.loc.y }
  end

  local scroll = frame["platform_scroll"]
  if scroll and scroll.valid then
    local sb = scroll.vertical_scrollbar
    if sb and sb.valid and st.scroll then
      -- clamp to available range
      local maxv = sb.maximum_value or sb.max_value or sb.value
      sb.value = math.min(maxv, math.max(0, st.scroll))
    end
  end
end

-- Apply the configured width/height to all platform entry buttons in-place.
-- (Kept for future row-size controls; not bound to header buttons.)
local function apply_platform_button_size(player)
  local frame = player.gui.screen[UI_NAME]
  if not (frame and frame.valid) then return end

  local st = ui_state(player.index)
  local scroll = frame["platform_scroll"]
  local list = (scroll and scroll.valid) and scroll["platform_list"] or nil
  if not (list and list.valid) then return end

  for _, child in ipairs(list.children) do
    if child and child.valid then
      child.style.minimal_width  = st.button_w
      child.style.maximal_width  = st.button_w
      child.style.minimal_height = st.button_h
      child.style.maximal_height = st.button_h
    end
  end
end

-- Adjust stored row width/height and re-apply without rebuilding the UI.
-- (Unbound to header buttons; available if you add row-size controls later.)
local function nudge_platform_dims(player, dw, dh)
  local st = ui_state(player.index)
  st.button_w = math.max(100, math.min(600, st.button_w + (dw or 0)))
  st.button_h = math.max(20,  math.min(60,  st.button_h + (dh or 0)))
  apply_platform_button_size(player)
end

-- NEW: Adjust the WINDOW (frame) size in place; used by -W/+W/-H/+H.
local function nudge_window_dims(player, dw, dh)
  local st = ui_state(player.index)
  st.w = math.max(360, math.min(1400, st.w + (dw or 0)))
  st.h = math.max(320, math.min(1400, st.h + (dh or 0)))

  local frame = player.gui.screen[UI_NAME]
  if frame and frame.valid then
    frame.style.minimal_width  = st.w
    frame.style.minimal_height = st.h
  end
end

local function collect_platforms(force)
  local entries = {}
  if not (force and force.valid and force.platforms) then return entries end
  for _, p in pairs(force.platforms) do
    if p and p.valid then
      entries[#entries + 1] = {
        id = p.index,
        caption = p.name or ("Platform " .. tostring(p.index)),
        surface_name = p.surface and p.surface.name or nil
      }
    end
  end
  return entries
end

-- Kept for completeness; not used by the current header controls.
local function safe_sprite_button(parent, name, sprite, tooltip)
  local ok, elem = pcall(function()
    return parent.add{
      type   = "sprite-button",
      name   = name,
      sprite = sprite,
      style  = "frame_action_button",
      tooltip = tooltip,
    }
  end)
  if ok and elem then return elem end
  return parent.add{ type = "button", name = name, caption = tooltip or name }
end

local function build_platform_ui(player)
  local st = ui_state(player.index)
  local frame = player.gui.screen.add{
    type = "frame",
    name = UI_NAME,
    direction = "vertical"
  }
  frame.auto_center = true

  -- header wrapper uses vertical flow so we can stack rows
  local header = frame.add{ type = "flow", direction = "vertical", name = "sp_header" }

  -- Row 1: title + drag handle
  local titlebar = header.add{ type = "flow", direction = "horizontal", name = "sp_titlebar" }
  titlebar.add{
    type = "label",
    caption = {"gui.space-platforms-org-ui-title"},
    style = "frame_title"
  }
  local drag = titlebar.add{ type = "empty-widget", name = "drag_handle", style = "draggable_space_header" }
  drag.style.horizontally_stretchable = true
  drag.style.height = 24
  drag.drag_target = frame

  -- Row 2: left-aligned window size controls
  local controls = header.add{ type = "flow", direction = "horizontal", name = "sp_controls" }
  controls.style.horizontal_spacing = 2
  controls.add{ type = "button", name = HEADER_W_DEC, caption = "-W", style = "tool_button", maximal_width = 36, minimal_width = 36 }
  controls.add{ type = "button", name = HEADER_W_INC, caption = "+W", style = "tool_button", maximal_width = 36, minimal_width = 36 }
  controls.add{ type = "button", name = HEADER_H_DEC, caption = "-H", style = "tool_button", maximal_width = 36, minimal_width = 36 }
  controls.add{ type = "button", name = HEADER_H_INC, caption = "+H", style = "tool_button", maximal_width = 36, minimal_width = 36 }

  -- Collect platforms from the force
  local entries = collect_platforms(player.force)

  -- Scroll pane + vertical list container
  local scroll = frame.add{ type = "scroll-pane", name = "platform_scroll" }
  scroll.style.vertically_stretchable   = true
  scroll.style.horizontally_stretchable = true

  local list = scroll.add{ type = "flow", name = "platform_list", direction = "vertical" }
  list.style.vertically_stretchable   = true
  list.style.horizontally_stretchable = true

  if #entries == 0 then
    list.add{ type = "label", caption = {"gui.space-platforms-org-ui-no-platforms"} }
    apply_ui_state(player)
    return
  end

  local tan = { r = 0xD2/255, g = 0xB4/255, b = 0x8C/255 }
  for i, entry in ipairs(entries) do
    local b = list.add{
      type = "button",
      name = BUTTON_PREFIX .. tostring(entry.id),
      caption = entry.caption,
      tags = { platform_index = entry.id },
    }
    if b and b.valid then
      b.style.horizontally_stretchable = true
      -- keep fixed row size defaults; change via dedicated row-size controls if needed
      b.style.minimal_width  = st.button_w
      b.style.maximal_width  = st.button_w
      b.style.minimal_height = st.button_h
      b.style.maximal_height = st.button_h
      b.style.top_padding    = 2
      b.style.bottom_padding = 2
      if i % 2 == 0 then
        local gs = { base = { position = {0, 0}, corner_size = 8, tint = tan } }
        b.style.default_graphical_set  = gs
        b.style.hovered_graphical_set  = gs
        b.style.clicked_graphical_set  = gs
        b.style.disabled_graphical_set = gs
      end
    end
  end

  -- Ensure sizes and placement are applied on first open.
  apply_platform_button_size(player)
  apply_ui_state(player)
end

local function rebuild_ui(player)
  capture_ui_state(player)
  local existing = player.gui.screen[UI_NAME]
  if existing and existing.valid then existing.destroy() end
  build_platform_ui(player)
end

local function toggle_platform_ui(player, refresh)
  local existing = player.gui.screen[UI_NAME]
  if existing and existing.valid then
    if refresh then
      rebuild_ui(player)
    else
      capture_ui_state(player)
      existing.destroy()
    end
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

local function open_platform_view(player, pid)
  if not pid then return end
  local plat
  if player.force and player.force.valid and player.force.platforms then
    for _, p in pairs(player.force.platforms) do
      if p.index == pid then plat = p; break end
    end
  end
  if not (plat and plat.valid) then
    log("UI: platform not found id=" .. tostring(pid))
    return
  end
  local surf = plat.surface
  if not (surf and surf.valid) then
    log("UI: platform surface invalid id=" .. tostring(pid))
    return
  end
  local pos = {x = 0, y = 0}
  local safe = surf.find_non_colliding_position("character", pos, 64, 1) or pos
  pcall(function()
    player.set_controller{
      type = defines.controllers.remote,
      surface = surf,
      position = safe,
      start_zoom = 0.7,
    }
    player.zoom_to_world(safe, 0.8, surf)
  end)
  log("UI: opened platform id=" .. pid .. " surface=" .. surf.name)
end

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  local player  = game.get_player(event.player_index)
  if not (element and element.valid and player) then return end

  local name = element.name

  -- Header controls resize the WINDOW (frame), not the list rows.
  if name == HEADER_W_DEC then
    nudge_window_dims(player, -20, 0)
    return
  elseif name == HEADER_W_INC then
    nudge_window_dims(player,  20, 0)
    return
  elseif name == HEADER_H_DEC then
    nudge_window_dims(player, 0, -20)
    return
  elseif name == HEADER_H_INC then
    nudge_window_dims(player, 0,  20)
    return
  end

  -- Platform selection
  if not name or name:sub(1, #BUTTON_PREFIX) ~= BUTTON_PREFIX then return end
  local pid = element.tags and element.tags.platform_index
      or tonumber(name:sub(#BUTTON_PREFIX + 1))
  if not pid then return end
  open_platform_view(player, pid)
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element
  if element and element.name == UI_NAME then
    local player = game.get_player(event.player_index)
    if player then capture_ui_state(player) end
    element.destroy()
  end
end)

script.on_event(defines.events.on_gui_location_changed, function(event)
  local el = event.element
  if not (el and el.valid and el.name == UI_NAME) then return end
  local st = ui_state(event.player_index)
  st.loc = {x = el.location.x, y = el.location.y}
end)

script.on_init(function()
  local g = get_global()
  g.spui = g.spui or {}
end)

script.on_configuration_changed(function()
  local g = get_global()
  g.spui = g.spui or {}
end)

local function rebuild_all_open()
  for _, p in pairs(game.connected_players) do
    local frame = p.gui.screen[UI_NAME]
    if frame and frame.valid then rebuild_ui(p) end
  end
end

if defines.events.on_platform_created then
  script.on_event(defines.events.on_platform_created, rebuild_all_open)
end
if defines.events.on_platform_removed then
  script.on_event(defines.events.on_platform_removed, rebuild_all_open)
end

script.on_event(defines.events.on_surface_created, function(e)
  local s = game.surfaces[e.surface_index]
  if s and s.valid and s.name and s.name:find("^platform%-") then
    rebuild_all_open()
  end
end)

script.on_event(defines.events.on_surface_deleted, function()
  rebuild_all_open()
end)
