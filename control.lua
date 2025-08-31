-- luacheck: globals global script defines log

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"

-- Header (window-size) button ids
local HEADER_W_DEC = "sp-size-w-dec"
local HEADER_W_INC = "sp-size-w-inc"
local HEADER_H_DEC = "sp-size-h-dec"
local HEADER_H_INC = "sp-size-h-inc"

-- Window size step in pixels
local SIZE_INC = 20

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
    -- w/h = window size; button_w/h = list row size
    st = { w = 440, h = 528, loc = nil, scroll = 0, button_w = 260, button_h = 24 }
    g.spui[pi] = st
  end
  return st
end

-- Capture current frame geometry/scroll.
local function capture_ui_state(player)
  local st = ui_state(player.index)
  local frame = player.gui.screen[UI_NAME]
  if frame and frame.valid then
    st.w = tonumber(frame.style.minimal_width) or st.w
    st.h = tonumber(frame.style.minimal_height) or st.h
    local loc = frame.location
    if loc and loc.x and loc.y then
      st.loc = { x = loc.x, y = loc.y }
    end
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

-- Reapply saved geometry/scroll.
local function apply_ui_state(player)
  local st = ui_state(player.index)
  local frame = player.gui.screen[UI_NAME]
  if not (frame and frame.valid) then return end
  if st.w then frame.style.minimal_width  = st.w end
  if st.h then frame.style.minimal_height = st.h end
  if st.loc and st.loc.x and st.loc.y then
    frame.location = { x = st.loc.x, y = st.loc.y }
  end
  local scroll = frame["platform_scroll"]
  if scroll and scroll.valid then
    local sb = scroll.vertical_scrollbar
    if sb and sb.valid and st.scroll then
      local maxv = sb.maximum_value or sb.max_value or sb.value
      sb.value = math.min(maxv, math.max(0, st.scroll))
    end
  end
end

-- Apply configured width/height to all list-row buttons in place.
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

-- Row-size adjuster (kept in case you add row-size controls later).
local function nudge_platform_dims(player, dw, dh)
  local st = ui_state(player.index)
  st.button_w = math.max(100, math.min(600, st.button_w + (dw or 0)))
  st.button_h = math.max(20,  math.min(60,  st.button_h + (dh or 0)))
  apply_platform_button_size(player)
end

-- Window-size adjuster for -W/+W/-H/+H.
local function nudge_window_dims(player, dw, dh)
  local st = ui_state(player.index)
  st.w = math.max(360, math.min(1600, st.w + (dw or 0)))
  st.h = math.max(320, math.min(1600, st.h + (dh or 0)))

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

-- Build UI ---------------------------------------------------------------

local function build_platform_ui(player)
  local st = ui_state(player.index)

  local frame = player.gui.screen.add{
    type = "frame",
    name = UI_NAME,
    direction = "vertical"
  }
  frame.auto_center = true

  -- Header (stacked)
  local header = frame.add{ type = "flow", direction = "vertical", name = "sp_header" }

  -- Title row
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

  -- Controls row: revert to standard tool_button (no color)
  local controls = header.add{ type = "flow", direction = "horizontal", name = "sp_controls" }
  controls.style.horizontal_spacing = 2

  local function add_hdr_btn(name, caption)
    local b = controls.add{ type = "button", name = name, caption = caption, style = "tool_button" }
    -- Fix width/height so captions don't ellipsize and all buttons match.
    b.style.minimal_width  = 44
    b.style.maximal_width  = 44
    b.style.minimal_height = 24
    b.style.maximal_height = 24
    return b
  end

  add_hdr_btn(HEADER_W_DEC, "-W")
  add_hdr_btn(HEADER_W_INC, "+W")
  add_hdr_btn(HEADER_H_DEC, "-H")
  add_hdr_btn(HEADER_H_INC, "+H")

  -- Scroll pane + list
  local entries = collect_platforms(player.force)

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

  -- Build rows with alternating background styles (default / tan).
  for i, entry in ipairs(entries) do
    local style_name = (i % 2 == 1) and "sp_list_button_tan" or "button"
    local row = list.add{
      type = "button",
      name = BUTTON_PREFIX .. tostring(entry.id),
      caption = entry.caption,
      style = style_name,
      tags = { platform_index = entry.id },
    }
    if row and row.valid then
      row.style.horizontally_stretchable = true
      row.style.minimal_width  = st.button_w
      row.style.maximal_width  = st.button_w
      row.style.minimal_height = st.button_h
      row.style.maximal_height = st.button_h
      row.style.top_padding    = 2
      row.style.bottom_padding = 2
    end
  end

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

-- Events ----------------------------------------------------------------

script.on_event("space-platform-org-ui-toggle", function(event)
  local player = game.get_player(event.player_index)
  if player then toggle_platform_ui(player) end
end)

local function open_platform_view(player, pid)
  if not pid then return end
  local plat
  if player.force and player.force.valid and player.force.platforms then
    for _, p in pairs(player.force.platforms) do
      if p.index == pid then plat = p; break end
    end
  end
  if not (plat and plat.valid) then return end
  local surf = plat.surface
  if not (surf and surf.valid) then return end
  local pos = {x = 0, y = 0}
  local safe = surf.find_non_colliding_position("character", pos, 64, 1) or pos
  pcall(function()
    player.set_controller{
      type = defines.controllers.remote,
      surface = surf,
      position = safe,
      start_zoom = 0.7
    }
    player.zoom_to_world(safe, 0.8, surf)
  end)
end

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  local player  = game.get_player(event.player_index)
  if not (element and element.valid and player) then return end

  local name = element.name
  if name == HEADER_W_DEC then nudge_window_dims(player, -SIZE_INC, 0); return end
  if name == HEADER_W_INC then nudge_window_dims(player,  SIZE_INC, 0); return end
  if name == HEADER_H_DEC then nudge_window_dims(player, 0, -SIZE_INC); return end
  if name == HEADER_H_INC then nudge_window_dims(player, 0,  SIZE_INC); return end

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
  st.loc = { x = el.location.x, y = el.location.y }
end)

script.on_init(function()
  local g = get_global(); g.spui = g.spui or {}
end)

script.on_configuration_changed(function()
  local g = get_global(); g.spui = g.spui or {}
end)

local function rebuild_all_open()
  for _, p in pairs(game.connected_players) do
    local frame = p.gui.screen[UI_NAME]
    if frame and frame.valid then rebuild_ui(p) end
  end
end

if defines.events.on_platform_created then
  script.on_event(defines.events.on_platform_created, rebuild_all_open) end
if defines.events.on_platform_removed then
  script.on_event(defines.events.on_platform_removed, rebuild_all_open) end

script.on_event(defines.events.on_surface_created, function(e)
  local s = game.surfaces[e.surface_index]
  if s and s.valid and s.name and s.name:find("^platform%-") then rebuild_all_open() end
end)

script.on_event(defines.events.on_surface_deleted, function()
  rebuild_all_open()
end)
