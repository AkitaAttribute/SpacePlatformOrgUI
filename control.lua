-- luacheck: globals global script defines log

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"

-- Header controls
local HEADER_W_DEC = "sp-size-w-dec"
local HEADER_W_INC = "sp-size-w-inc"
local HEADER_H_DEC = "sp-size-h-dec"
local HEADER_H_INC = "sp-size-h-inc"
local HEADER_ADD_FOLDER = "sp-add-folder"

-- Folder/UI ids & prefixes
local FOLDER_ROW_PREFIX      = "sp-folder-row-"          -- folder header button
local FOLDER_TOGGLE_PREFIX   = "sp-folder-toggle-"       -- expand/collapse sprite
local FOLDER_DELETE_PREFIX   = "sp-folder-delete-"       -- delete folder sprite
local MOVE_MENU_NAME         = "sp-move-menu"            -- move popup frame
local MOVE_OPEN_PREFIX       = "sp-move-open-"           -- per-platform ⋯ button
local MOVE_TARGET_PREFIX     = "sp-move-target-"         -- target selection button

-- Window size step in pixels
local SIZE_INC = 20

-- ---------- State ----------

local function get_global()
  local g = rawget(_G, "global")
  if type(g) ~= "table" then g = {}; rawset(_G, "global", g) end
  return g
end

local function ui_state(pi)
  local g = get_global()
  g.spui = g.spui or {}
  local st = g.spui[pi]
  if not st then
    st = { w = 440, h = 528, loc = nil, scroll = 0, button_w = 260, button_h = 24 }
    g.spui[pi] = st
  end
  return st
end

-- Folder model (per player)
-- global.spfolders[player_index] = {
--   next_id = 1,
--   folders = { [id] = { name="Folder N", order=int, expanded=true } },
--   order = { id1, id2, ... },
--   platform_folder = { [platform_index] = folder_id or nil },
-- }
local function folder_model(pi)
  local g = get_global()
  g.spfolders = g.spfolders or {}
  local m = g.spfolders[pi]
  if not m then
    m = { next_id = 1, folders = {}, order = {}, platform_folder = {} }
    g.spfolders[pi] = m
  end
  return m
end

-- ---------- UI geometry ----------

local function capture_ui_state(player)
  local st = ui_state(player.index)
  local frame = player.gui.screen[UI_NAME]
  if frame and frame.valid then
    st.w = tonumber(frame.style.minimal_width) or st.w
    st.h = tonumber(frame.style.minimal_height) or st.h
    local loc = frame.location
    if loc and loc.x and loc.y then st.loc = { x = loc.x, y = loc.y } end
    local scroll = frame["platform_scroll"]
    if scroll and scroll.valid then
      local sb = scroll.vertical_scrollbar
      if sb and sb.valid then st.scroll = tonumber(sb.value) or st.scroll or 0 end
    end
  end
  return st
end

local function apply_ui_state(player)
  local st = ui_state(player.index)
  local frame = player.gui.screen[UI_NAME]
  if not (frame and frame.valid) then return end
  if st.w then frame.style.minimal_width  = st.w end
  if st.h then frame.style.minimal_height = st.h end
  if st.loc and st.loc.x and st.loc.y then frame.location = { x = st.loc.x, y = st.loc.y } end
  local scroll = frame["platform_scroll"]
  if scroll and scroll.valid then
    local sb = scroll.vertical_scrollbar
    if sb and sb.valid and st.scroll then
      local maxv = sb.maximum_value or sb.max_value or sb.value
      sb.value = math.min(maxv, math.max(0, st.scroll))
    end
  end
end

-- Find the button inside a row flow
local function get_row_button(row)
  if not (row and row.valid and row.type == "flow") then return nil end
  for _, c in ipairs(row.children) do
    if c and c.valid and c.type == "button" and (c.tags and c.tags.platform_index) then
      return c
    end
  end
  return nil
end

-- Apply the configured width/height to all platform entry buttons in-place.
local function apply_platform_button_size(player)
  local frame = player.gui.screen[UI_NAME]
  if not (frame and frame.valid) then return end
  local st = ui_state(player.index)
  local scroll = frame["platform_scroll"]
  local list = (scroll and scroll.valid) and scroll["platform_list"] or nil
  if not (list and list.valid) then return end
  for _, row in ipairs(list.children) do
    if row and row.valid and row.tags and row.tags.kind == "row" then
      local btn = get_row_button(row)
      if btn and btn.valid then
        btn.style.minimal_width  = st.button_w
        btn.style.maximal_width  = st.button_w
        btn.style.minimal_height = st.button_h
        btn.style.maximal_height = st.button_h
      end
    end
  end
end

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

-- ---------- Data helpers ----------

local function collect_platforms(force)
  local t = {}
  if not (force and force.valid and force.platforms) then return t end
  for _, p in pairs(force.platforms) do
    if p and p.valid then
      t[#t+1] = { id = p.index, caption = p.name or ("Platform " .. p.index) }
    end
  end
  table.sort(t, function(a,b) return (a.caption or "") < (b.caption or "") end)
  return t
end

local function add_folder(player, name)
  local m = folder_model(player.index)
  local id = m.next_id; m.next_id = id + 1
  m.folders[id] = { name = name or ("Folder " .. id), order = #m.order + 1, expanded = true }
  table.insert(m.order, id)
end

local function delete_folder(player, folder_id)
  local m = folder_model(player.index)
  if not m.folders[folder_id] then return end
  for pid, fid in pairs(m.platform_folder) do
    if fid == folder_id then m.platform_folder[pid] = nil end
  end
  m.folders[folder_id] = nil
  for i, id in ipairs(m.order) do
    if id == folder_id then table.remove(m.order, i); break end
  end
end

local function assign_platform(player, platform_id, folder_id) -- folder_id may be nil for Unsorted
  local m = folder_model(player.index)
  if folder_id and not m.folders[folder_id] then return end
  m.platform_folder[platform_id] = folder_id
end

-- ---------- UI build ----------

local function destroy_move_menu(player)
  local menu = player.gui.screen[MOVE_MENU_NAME]
  if menu and menu.valid then menu.destroy() end
end

local function add_row(list_flow, style_name, caption, platform_id)
  local row = list_flow.add{ type = "flow", direction = "horizontal", tags = { kind = "row" } }

  local btn = row.add{
    type = "button",
    name = BUTTON_PREFIX .. tostring(platform_id),  -- keep this name for click handling
    caption = caption,
    style = style_name,
    tags = { platform_index = platform_id },
  }
  btn.style.horizontally_stretchable = true
  btn.style.top_padding    = 2
  btn.style.bottom_padding = 2
  btn.style.left_padding   = 6
  btn.style.right_padding  = 6
  btn.style.minimal_width  = 260
  btn.style.maximal_width  = 260
  btn.style.minimal_height = 24
  btn.style.maximal_height = 24

  local mv = row.add{
    type = "button",
    name = MOVE_OPEN_PREFIX .. tostring(platform_id),
    caption = "⋯",
    style = "tool_button",
    tooltip = {"", "Move to folder"},
  }
  mv.style.minimal_width  = 24
  mv.style.maximal_width  = 24
  mv.style.minimal_height = 24
  mv.style.maximal_height = 24

  return row
end

local function build_platform_list(player, frame)
  local m  = folder_model(player.index)
  local entries = collect_platforms(player.force)

  local scroll = frame.add{ type = "scroll-pane", name = "platform_scroll" }
  scroll.style.vertically_stretchable   = true
  scroll.style.horizontally_stretchable = true

  local list = scroll.add{ type = "flow", name = "platform_list", direction = "vertical" }
  list.style.vertically_stretchable   = true
  list.style.horizontally_stretchable = true

  -- Render folders
  for _, fid in ipairs(m.order) do
    local f = m.folders[fid]
    if f then
      local bar = list.add{ type = "flow", direction = "horizontal" }
      local toggle = bar.add{
        type = "sprite-button", name = FOLDER_TOGGLE_PREFIX .. fid,
        sprite = f.expanded and "utility/collapse" or "utility/expand",
        style = "frame_action_button", tooltip = {"", f.expanded and "Collapse" or "Expand"}
      }
      toggle.style.minimal_width  = 24
      toggle.style.maximal_width  = 24
      local head = bar.add{
        type = "button", name = FOLDER_ROW_PREFIX .. fid,
        caption = "  " .. (f.name or ("Folder " .. fid)),
        style = "button",
        tooltip = {"", "Folder: ", f.name}
      }
      head.style.horizontally_stretchable = true
      bar.add{
        type = "sprite-button", name = FOLDER_DELETE_PREFIX .. fid,
        sprite = "utility/close_fat", style = "frame_action_button",
        tooltip = {"", "Delete folder"}
      }

      if f.expanded then
        for _, e in ipairs(entries) do
          if m.platform_folder[e.id] == fid then
            local idx = #list.children + 1
            local style_name = (idx % 2 == 1) and "sp_list_button_tan" or "button"
            add_row(list, style_name, e.caption, e.id)
          end
        end
      end
    end
  end

  -- Unsorted section header: spacer + label
  do
    local bar = list.add{ type = "flow", direction = "horizontal" }
    local spacer = bar.add{ type = "empty-widget", name = "sp-unsorted-spacer" }
    spacer.style.minimal_width = 24
    spacer.style.maximal_width = 24
    spacer.style.minimal_height = 1
    spacer.style.maximal_height = 1
    local label = bar.add{ type = "label", caption = "  Unsorted", style = "subheader_caption_label" }
    label.style.horizontally_stretchable = true
  end

  for _, e in ipairs(entries) do
    if not m.platform_folder[e.id] then
      local idx = #list.children + 1
      local style_name = (idx % 2 == 1) and "sp_list_button_tan" or "button"
      add_row(list, style_name, e.caption, e.id)
    end
  end

  -- Apply sizes/scroll
  apply_platform_button_size(player)
  apply_ui_state(player)
end

local function build_platform_ui(player)
  destroy_move_menu(player)

  local frame = player.gui.screen.add{
    type = "frame", name = UI_NAME, direction = "vertical"
  }
  frame.auto_center = true

  -- Header
  local header = frame.add{ type = "flow", direction = "vertical", name = "sp_header" }

  -- Title
  local titlebar = header.add{ type = "flow", direction = "horizontal", name = "sp_titlebar" }
  titlebar.add{ type = "label", caption = {"gui.space-platforms-org-ui-title"}, style = "frame_title" }
  local drag = titlebar.add{ type = "empty-widget", name = "drag_handle", style = "draggable_space_header" }
  drag.style.horizontally_stretchable = true; drag.style.height = 24; drag.drag_target = frame

  -- Controls row
  local controls = header.add{ type = "flow", direction = "horizontal", name = "sp_controls" }
  controls.style.horizontal_spacing = 2

  local function add_hdr_btn(name, caption)
    local b = controls.add{ type = "button", name = name, caption = caption, style = "tool_button" }
    b.style.minimal_width  = 44; b.style.maximal_width  = 44
    b.style.minimal_height = 24; b.style.maximal_height = 24
    return b
  end

  add_hdr_btn(HEADER_W_DEC, "-W")
  add_hdr_btn(HEADER_W_INC, "+W")
  add_hdr_btn(HEADER_H_DEC, "-H")
  add_hdr_btn(HEADER_H_INC, "+H")
  controls.add{ type = "button", name = HEADER_ADD_FOLDER, caption = "+F", style = "tool_button", tooltip = {"", "Add folder"} }

  -- List
  build_platform_list(player, frame)
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
    if refresh then rebuild_ui(player)
    else capture_ui_state(player); existing.destroy() end
  else
    build_platform_ui(player)
  end
end

-- ---------- Events ----------

script.on_event("space-platform-org-ui-toggle", function(e)
  local p = game.get_player(e.player_index); if p then toggle_platform_ui(p) end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  local player  = game.get_player(event.player_index)
  if not (element and element.valid and player) then return end
  local name = element.name

  -- Window size
  if name == HEADER_W_DEC then nudge_window_dims(player, -SIZE_INC, 0); return end
  if name == HEADER_W_INC then nudge_window_dims(player,  SIZE_INC, 0); return end
  if name == HEADER_H_DEC then nudge_window_dims(player, 0, -SIZE_INC); return end
  if name == HEADER_H_INC then nudge_window_dims(player, 0,  SIZE_INC); return end

  -- Add folder
  if name == HEADER_ADD_FOLDER then add_folder(player, nil); rebuild_ui(player); return end

  -- Folder toggle
  do
    local fid = name:match("^"..FOLDER_TOGGLE_PREFIX.."(%d+)$")
    if fid then
      fid = tonumber(fid)
      local m = folder_model(player.index)
      local f = m.folders[fid]; if not f then return end
      f.expanded = not f.expanded
      rebuild_ui(player)
      return
    end
  end

  -- Folder delete
  do
    local fid = name:match("^"..FOLDER_DELETE_PREFIX.."(%d+)$")
    if fid then
      delete_folder(player, tonumber(fid))
      rebuild_ui(player)
      return
    end
  end

  -- Open move-to menu
  do
    local pid = name:match("^"..MOVE_OPEN_PREFIX.."(%d+)$")
    if pid then
      pid = tonumber(pid)
      local menu = player.gui.screen[MOVE_MENU_NAME]; if menu and menu.valid then menu.destroy() end
      menu = player.gui.screen.add{ type = "frame", name = MOVE_MENU_NAME, direction = "vertical" }
      menu.auto_center = true
      local m = folder_model(player.index)
      for _, fid in ipairs(m.order) do
        local f = m.folders[fid]
        if f then
          menu.add{
            type = "button",
            name = MOVE_TARGET_PREFIX .. fid .. "-" .. pid,
            caption = f.name, style = "button"
          }
        end
      end
      menu.add{ type = "button", name = MOVE_TARGET_PREFIX .. "none-" .. pid, caption = "(Unsorted)", style = "button" }
      return
    end
  end

  -- Choose move target
  do
    local fid, pid = name:match("^"..MOVE_TARGET_PREFIX.."([^%-]+)%-(%d+)$")
    if fid and pid then
      pid = tonumber(pid)
      if fid == "none" then
        assign_platform(player, pid, nil)
      else
        assign_platform(player, pid, tonumber(fid))
      end
      local menu = player.gui.screen[MOVE_MENU_NAME]; if menu and menu.valid then menu.destroy() end
      rebuild_ui(player)
      return
    end
  end

  -- Platform selection (open view)
  if name:sub(1, #BUTTON_PREFIX) == BUTTON_PREFIX or (element.tags and element.tags.platform_index) then
    local pid = element.tags and element.tags.platform_index
    if not pid then pid = tonumber(name:sub(#BUTTON_PREFIX + 1)) end
    if not pid then return end

    local plat
    if player.force and player.force.valid and player.force.platforms then
      for _, p in pairs(player.force.platforms) do
        if p.index == pid then plat = p; break end
      end
    end
    if not (plat and plat.valid) then return end
    local surf = plat.surface; if not (surf and surf.valid) then return end
    local pos = {x = 0, y = 0}
    local safe = surf.find_non_colliding_position("character", pos, 64, 1) or pos
    pcall(function()
      player.set_controller{ type = defines.controllers.remote, surface = surf, position = safe, start_zoom = 0.7 }
      player.zoom_to_world(safe, 0.8, surf)
    end)
    return
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element
  local player  = game.get_player(event.player_index)
  if not player then return end
  if element and element.name == UI_NAME then
    capture_ui_state(player)
    element.destroy()
    local menu = player.gui.screen[MOVE_MENU_NAME]; if menu and menu.valid then menu.destroy() end
  elseif element and element.name == MOVE_MENU_NAME then
    element.destroy()
  end
end)

script.on_event(defines.events.on_gui_location_changed, function(event)
  local el = event.element
  if not (el and el.valid and el.name == UI_NAME) then return end
  local st = ui_state(event.player_index)
  st.loc = { x = el.location.x, y = el.location.y }
end)

script.on_init(function() local g=get_global(); g.spui=g.spui or {}; g.spfolders=g.spfolders or {} end)
script.on_configuration_changed(function() local g=get_global(); g.spui=g.spui or {}; g.spfolders=g.spfolders or {} end)

local function rebuild_all_open()
  for _, p in pairs(game.connected_players) do
    local frame = p.gui.screen[UI_NAME]
    if frame and frame.valid then rebuild_ui(p) end
  end
end

if defines.events.on_platform_created then script.on_event(defines.events.on_platform_created, rebuild_all_open) end
if defines.events.on_platform_removed then script.on_event(defines.events.on_platform_removed, rebuild_all_open) end
script.on_event(defines.events.on_surface_created, function(e)
  local s = game.surfaces[e.surface_index]
  if s and s.valid and s.name and s.name:find("^platform%-") then rebuild_all_open() end
end)
script.on_event(defines.events.on_surface_deleted, function() rebuild_all_open() end)
