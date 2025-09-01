-- control.lua
-- Space Platform Organizer UI
-- Fixed-size frame + bottom-right resize handle + folders + debug overlay

-- ========= Constants =========
local UI_NAME               = "space-platform-org-ui"
local BUTTON_PREFIX         = "sp-ui-btn-"

-- Header controls
local HEADER_ADD_FOLDER     = "sp-add-folder"

-- Move menu
local MOVE_MENU_NAME        = "sp-move-menu"
local UNSORTED_ID           = -1

-- Rename dialog
local RENAME_MENU_NAME      = "sp-rename-menu"
local RENAME_INPUT_NAME     = "sp-rename-input"

-- Delete confirmation
local DELETE_MENU_NAME      = "sp-delete-confirm"

-- Top-level resize handle
local RESIZE_HANDLE_NAME    = "sp-resize-handle"
local RESIZE_SIZE           = 16

-- Window size limits
local MIN_W, MIN_H, MAX_W, MAX_H = 360, 320, 1400, 1400

-- Debug overlay always on (shows TL/BR boxes and size label)
local DEBUG                 = true

-- ========= Global state =========
local function ensure_global_tables()
  if type(global) ~= "table" then rawset(_G, "global", {}) end
  global.spui      = global.spui or {}       -- per-player ui state
  global.spfolders = global.spfolders or {}  -- per-player folder model
end

local function ui_state(pi)
  ensure_global_tables()
  local st = global.spui[pi]
  if not st then
    st = {
      w = 720, h = 480,
      loc = nil,
      scroll = 0,
      button_w = 260, button_h = 24,
      follow = false,
    }
    global.spui[pi] = st
  end
  return st
end

local function folder_model(pi)
  ensure_global_tables()
  local m = global.spfolders[pi]
  if not m then
    m = { next_id = 1, folders = {}, order = {}, platform_folder = {} }
    global.spfolders[pi] = m
  end
  return m
end

-- ========= Helpers =========
local function num(x) return tonumber(x) or 0 end

-- Lock a frame to an exact size and prevent stretching
local function fix_frame_size(frame, w, h)
  frame.style.horizontally_stretchable = false
  frame.style.vertically_stretchable   = false
  frame.style.minimal_width  = w
  frame.style.maximal_width  = w
  frame.style.minimal_height = h
  frame.style.maximal_height = h
end

-- ========= State capture/apply =========
local function capture_ui_state(player)
  local st = ui_state(player.index)
  local frame = player.gui.screen[UI_NAME]
  if frame and frame.valid then
    local w = tonumber(frame.style.minimal_width)
    local h = tonumber(frame.style.minimal_height)
    if w then st.w = w end
    if h then st.h = h end
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

local function update_info_label(player)
  local frame = player.gui.screen[UI_NAME]
  if not (frame and frame.valid) then return end
  local tb = frame["sp_titlebar"]
  if not (tb and tb.valid) then return end
  local info = tb["sp_dbg_info"]
  if not (info and info.valid) then return end
  local loc = frame.location or {x=0,y=0}
  local w   = num(frame.style.minimal_width)
  local h   = num(frame.style.minimal_height)
  info.caption = string.format("  w=%d h=%d  @ %d,%d", w, h, loc.x or 0, loc.y or 0)
end

local function apply_ui_state(player)
  local st = ui_state(player.index)
  local frame = player.gui.screen[UI_NAME]
  if not (frame and frame.valid) then return end

  -- Hard lock size
  fix_frame_size(frame, st.w, st.h)

  -- Position
  if st.loc and st.loc.x and st.loc.y then
    frame.location = { x = st.loc.x, y = st.loc.y }
  else
    frame.auto_center = true
  end

  -- Scroll
  local scroll = frame["platform_scroll"]
  if scroll and scroll.valid then
    local sb = scroll.vertical_scrollbar
    if sb and sb.valid and st.scroll then
      local maxv = sb.maximum_value or sb.max_value or sb.value
      sb.value = math.min(maxv, math.max(0, st.scroll))
    end
  end

  update_info_label(player)
end

-- ========= Resize handle positioning =========
local function handle_location_for(player)
  local frame = player.gui.screen[UI_NAME]
  if not (frame and frame.valid) then return {x=0, y=0} end
  local loc = frame.location or {x=0, y=0}
  local w   = num(frame.style.minimal_width)
  local h   = num(frame.style.minimal_height)
  return { x = loc.x + w - RESIZE_SIZE, y = loc.y + h - RESIZE_SIZE }
end

local function ensure_resizer(player)
  local h = player.gui.screen[RESIZE_HANDLE_NAME]
  if h and h.valid then return h end

  -- A small top-level frame with a draggable_space child that drags its PARENT
  h = player.gui.screen.add{ type = "frame", name = RESIZE_HANDLE_NAME, direction = "vertical" }
  h.style.padding = 0
  h.style.margin  = 0
  h.style.minimal_width  = RESIZE_SIZE
  h.style.minimal_height = RESIZE_SIZE
  h.style.maximal_width  = RESIZE_SIZE
  h.style.maximal_height = RESIZE_SIZE

  local d = h.add{ type = "empty-widget", style = "draggable_space" }
  d.style.width  = RESIZE_SIZE
  d.style.height = RESIZE_SIZE
  d.drag_target  = h

  h.location = handle_location_for(player)
  h.bring_to_front()
  return h
end

local function position_resizer(player)
  local h = ensure_resizer(player)
  if not (h and h.valid) then return end
  local want = handle_location_for(player)
  local loc  = h.location or {x=0, y=0}
  if loc.x ~= want.x or loc.y ~= want.y then
    h.location = want
  end
  h.bring_to_front()
end

-- ========= Debug markers =========
local function ensure_dbg_box(player, name, label)
  local el = player.gui.screen[name]
  if el and el.valid then return el end
  el = player.gui.screen.add{ type="frame", name=name, direction="horizontal" }
  el.style.padding = 0
  el.style.margin  = 0
  el.style.minimal_width  = 24
  el.style.minimal_height = 24
  el.style.maximal_width  = 24
  el.style.maximal_height = 24
  local lab = el.add{ type="label", caption=label }
  lab.style.font = "default-bold"
  lab.style.left_padding = 4
  return el
end

local function update_debug_markers(player)
  if not DEBUG then
    for _, n in pairs({"spui-dbg-tl","spui-dbg-br"}) do
      local e = player.gui.screen[n]; if e and e.valid then e.destroy() end
    end
    return
  end
  local frame = player.gui.screen[UI_NAME]
  if not (frame and frame.valid) then
    for _, n in pairs({"spui-dbg-tl","spui-dbg-br"}) do
      local e = player.gui.screen[n]; if e and e.valid then e.destroy() end
    end
    return
  end
  local tl = ensure_dbg_box(player, "spui-dbg-tl", "TL")
  tl.location = frame.location or {x=0,y=0}

  local br = ensure_dbg_box(player, "spui-dbg-br", "BR")
  local loc = handle_location_for(player)
  br.location = { x = loc.x, y = loc.y }
end

-- ========= Folder model =========
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

local function delete_folder_and_unassign(player, folder_id)
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

local function assign_platform(player, platform_id, folder_id)
  local m = folder_model(player.index)
  if folder_id and not m.folders[folder_id] then return end
  m.platform_folder[platform_id] = folder_id
end

local function folder_child_count(m, folder_id, entries)
  local n = 0
  for _, e in ipairs(entries) do
    if m.platform_folder[e.id] == folder_id then n = n + 1 end
  end
  return n
end

-- ========= Popups =========
local function destroy_move_menu(player)
  local menu = player.gui.screen[MOVE_MENU_NAME]
  if menu and menu.valid then menu.destroy() end
end
local function destroy_rename_menu(player)
  local dlg = player.gui.screen[RENAME_MENU_NAME]
  if dlg and dlg.valid then dlg.destroy() end
end
local function destroy_delete_menu(player)
  local dlg = player.gui.screen[DELETE_MENU_NAME]
  if dlg and dlg.valid then dlg.destroy() end
end

local function open_move_menu(player, platform_id)
  destroy_move_menu(player)
  local menu = player.gui.screen.add{ type = "frame", name = MOVE_MENU_NAME, direction = "vertical" }
  menu.auto_center = true
  local m = folder_model(player.index)
  for _, fid in ipairs(m.order) do
    local f = m.folders[fid]
    if f then
      menu.add{
        type = "button",
        name = "sp-move-target-" .. fid .. "-" .. platform_id,
        caption = f.name,
        style  = "button",
        tags   = { action = "move_to_folder", folder_id = fid, platform_id = platform_id }
      }
    end
  end
  menu.add{
    type = "button",
    name = "sp-move-target-none-" .. platform_id,
    caption = "(Unsorted)",
    style  = "button",
    tags   = { action = "move_to_folder", folder_id = UNSORTED_ID, platform_id = platform_id }
  }
end

local function open_rename_menu(player, folder_id)
  destroy_rename_menu(player)
  local m = folder_model(player.index)
  local f = m.folders[folder_id]; if not f then return end

  local dlg = player.gui.screen.add{ type = "frame", name = RENAME_MENU_NAME, direction = "vertical", tags = { folder_id = folder_id } }
  dlg.auto_center = true
  dlg.add{ type = "label", caption = "Rename folder:", style = "subheader_caption_label" }
  local tf = dlg.add{ type = "textfield", name = RENAME_INPUT_NAME, text = f.name or "" }
  tf.style.minimal_width = 240
  local row = dlg.add{ type = "flow", direction = "horizontal" }
  row.add{ type = "button", name = "sp-rename-ok", caption = "OK", style = "confirm_button", tags = { action = "rename_ok" } }
  row.add{ type = "button", name = "sp-rename-cancel", caption = "Cancel", style = "button", tags = { action = "rename_cancel" } }
  tf.focus(); tf.select_all()
end

local function open_delete_confirm(player, folder_id)
  destroy_delete_menu(player)
  local m = folder_model(player.index)
  local f = m.folders[folder_id]; if not f then return end

  local dlg = player.gui.screen.add{ type = "frame", name = DELETE_MENU_NAME, direction = "vertical", tags = { folder_id = folder_id } }
  dlg.auto_center = true
  dlg.add{ type = "label", caption = string.format('Are you sure you want to delete "%s"?', f.name or ("Folder " .. folder_id)), style = "subheader_caption_label" }
  local row = dlg.add{ type = "flow", direction = "horizontal" }
  row.add{ type = "button", name = "sp-delete-ok", caption = "Delete", style = "confirm_button", tags = { action = "delete_confirm_ok" } }
  row.add{ type = "button", name = "sp-delete-cancel", caption = "Cancel", style = "button", tags = { action = "delete_confirm_cancel" } }
end

-- ========= List building =========
local function get_row_button(row)
  if not (row and row.valid and row.type == "flow") then return nil end
  for _, c in ipairs(row.children) do
    if c and c.valid and c.type == "button" and (c.tags and c.tags.platform_index) then
      return c
    end
  end
  return nil
end

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

local function add_row(list_flow, style_name, caption, platform_id)
  local row = list_flow.add{ type = "flow", direction = "horizontal", tags = { kind = "row" } }

  local btn = row.add{
    type = "button",
    name = BUTTON_PREFIX .. tostring(platform_id),
    caption = caption,
    style   = style_name, -- standard button for platforms
    tags    = { platform_index = platform_id },
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
    name = "sp-move-open-" .. platform_id,
    caption = "⋯",
    style = "tool_button",
    tooltip = {"", "Move to folder"},
    tags = { action = "open_move_menu", platform_id = platform_id }
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
  scroll.style.horizontally_stretchable = true   -- allow it to fill available width

  local list = scroll.add{ type = "flow", name = "platform_list", direction = "vertical" }
  list.style.vertically_stretchable   = true
  list.style.horizontally_stretchable = true

  for _, fid in ipairs(m.order) do
    local f = m.folders[fid]
    if f then
      local count = folder_child_count(m, fid, entries)
      local bar = list.add{ type = "flow", direction = "horizontal" }

      local tog = bar.add{
        type   = "sprite-button",
        sprite = f.expanded and "utility/collapse" or "utility/expand",
        style  = "frame_action_button",
        tooltip = {"", f.expanded and "Collapse" or "Expand"},
        tags   = { action = "toggle_folder", folder_id = fid }
      }
      tog.style.minimal_width  = 24
      tog.style.maximal_width  = 24

      local head = bar.add{
        type = "button",
        caption = string.format("  %s (%d)", (f.name or ("Folder " .. fid)), count),
        style = "sp_list_button_tan",
        tooltip = {"", "Folder: ", f.name}
      }
      head.style.horizontally_stretchable = true

      local ren = bar.add{
        type = "button", caption = "✎", style = "tool_button",
        tooltip = {"", "Rename folder"},
        tags = { action = "open_rename_menu", folder_id = fid }
      }
      ren.style.minimal_width  = 24
      ren.style.maximal_width  = 24

      bar.add{
        type   = "sprite-button",
        sprite = "utility/close_fat",
        style  = "frame_action_button",
        tooltip = {"", "Delete folder"},
        tags   = { action = "open_delete_confirm", folder_id = fid }
      }

      if f.expanded then
        for _, e in ipairs(entries) do
          if m.platform_folder[e.id] == fid then
            add_row(list, "button", e.caption, e.id)
          end
        end
      end
    end
  end

  do
    local bar = list.add{ type = "flow", direction = "horizontal" }
    local spacer = bar.add{ type = "empty-widget" }
    spacer.style.minimal_width = 24; spacer.style.maximal_width = 24
    local label = bar.add{ type = "label", caption = "  Unsorted", style = "subheader_caption_label" }
    label.style.horizontally_stretchable = true
  end

  for _, e in ipairs(entries) do
    if not m.platform_folder[e.id] then
      add_row(list, "button", e.caption, e.id)
    end
  end

  apply_platform_button_size(player)
  apply_ui_state(player)
end

-- ========= Build UI =========
local function build_platform_ui(player)
  destroy_move_menu(player); destroy_rename_menu(player); destroy_delete_menu(player)

  local frame = player.gui.screen.add{ type = "frame", name = UI_NAME, direction = "vertical" }
  frame.style.padding = 0 -- exact sizing

  local st = ui_state(player.index)
  frame.auto_center = (st.loc == nil)

  -- Title bar (fixed height)
  local titlebar = frame.add{ type = "flow", direction = "horizontal", name = "sp_titlebar" }
  titlebar.style.height = 28
  local title = titlebar.add{ type = "label", caption = "Space Platforms", style = "frame_title" }
  title.style.left_padding = 6
  local tdrag = titlebar.add{ type = "empty-widget", name = "drag_handle", style = "draggable_space_header" }
  tdrag.style.horizontally_stretchable = true
  tdrag.style.height = 28
  tdrag.drag_target = frame
  -- Debug info label
  titlebar.add{ type="label", name="sp_dbg_info", caption="  w=?,h=? @ ?,?", style="label" }

  -- Controls row (fixed height)
  local controls = frame.add{ type = "flow", direction = "horizontal", name = "sp_controls" }
  controls.style.horizontal_spacing = 2
  controls.style.height = 28
  controls.add{ type = "button", name = HEADER_ADD_FOLDER, caption = "+F", style = "tool_button", tooltip = {"", "Add folder"} }

  -- Main list (fills remaining space)
  build_platform_list(player, frame)

  -- Footer to reserve space equal to handle size (visual padding at bottom)
  local footer = frame.add{ type = "flow", name = "sp_footer", direction = "horizontal" }
  footer.style.height = RESIZE_SIZE
  local spacer = footer.add{ type = "empty-widget" }
  spacer.style.horizontally_stretchable = true

  -- Prevent the top-level frame from stretching because of children
  frame.style.horizontally_stretchable = false
  frame.style.vertically_stretchable   = false

  -- Apply locked size/position and park the handle
  apply_ui_state(player)
  position_resizer(player)

  -- Keep handle glued each tick
  ui_state(player.index).follow = true

  -- Draw debug markers now
  update_debug_markers(player)
end

local function rebuild_ui(player)
  capture_ui_state(player)
  local existing = player.gui.screen[UI_NAME]
  if existing and existing.valid then existing.destroy() end
  build_platform_ui(player)
end

local function toggle_platform_ui(player, refresh)
  local frame = player.gui.screen[UI_NAME]
  if frame and frame.valid then
    if refresh then
      rebuild_ui(player)
    else
      capture_ui_state(player)
      frame.destroy()
      local h = player.gui.screen[RESIZE_HANDLE_NAME]
      if h and h.valid then h.destroy() end
      ui_state(player.index).follow = false
      update_debug_markers(player)
    end
  else
    build_platform_ui(player)
  end
end

-- ========= Events =========
script.on_event("space-platform-org-ui-toggle", function(e)
  local p = game.get_player(e.player_index); if p then toggle_platform_ui(p) end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  local player  = game.get_player(event.player_index)
  if not (element and element.valid and player) then return end

  local name = element.name
  local tags = element.tags or {}

  if name == HEADER_ADD_FOLDER then add_folder(player, nil); rebuild_ui(player); return end

  if tags.action == "toggle_folder" and tags.folder_id then
    local m = folder_model(player.index)
    local f = m.folders[tags.folder_id]; if not f then return end
    f.expanded = not f.expanded
    rebuild_ui(player); return
  end

  if tags.action == "open_delete_confirm" and tags.folder_id then open_delete_confirm(player, tags.folder_id); return end
  if tags.action == "delete_confirm_ok" then
    local dlg = player.gui.screen[DELETE_MENU_NAME]
    if dlg and dlg.valid then
      local fid = dlg.tags and dlg.tags.folder_id
      if fid then delete_folder_and_unassign(player, fid) end
      destroy_delete_menu(player); rebuild_ui(player)
    end
    return
  end
  if tags.action == "delete_confirm_cancel" then destroy_delete_menu(player); return end

  if tags.action == "open_move_menu" and tags.platform_id then open_move_menu(player, tags.platform_id); return end
  if tags.action == "move_to_folder" and tags.platform_id and tags.folder_id then
    local fid = (tags.folder_id == UNSORTED_ID) and nil or tags.folder_id
    assign_platform(player, tags.platform_id, fid)
    destroy_move_menu(player); rebuild_ui(player); return
  end

  if tags.action == "open_rename_menu" and tags.folder_id then open_rename_menu(player, tags.folder_id); return end
  if tags.action == "rename_ok" then
    local dlg = player.gui.screen[RENAME_MENU_NAME]
    if dlg and dlg.valid then
      local fid = dlg.tags and dlg.tags.folder_id
      if fid then
        local tf = dlg[RENAME_INPUT_NAME]
        local newname = tf and tf.valid and (tf.text or ""):gsub("^%s+", ""):gsub("%s+$", "") or ""
        if newname ~= "" then
          local m = folder_model(player.index)
          local f = m.folders[fid]; if f then f.name = newname end
        end
      end
      destroy_rename_menu(player); rebuild_ui(player)
    end
    return
  end
  if tags.action == "rename_cancel" then destroy_rename_menu(player); return end

  -- Platform selection (open platform view)
  if name:sub(1, #BUTTON_PREFIX) == BUTTON_PREFIX or (tags.platform_index) then
    local pid = tags.platform_index or tonumber(name:sub(#BUTTON_PREFIX + 1)); if not pid then return end
    local plat
    if player.force and player.force.valid and player.force.platforms then
      for _, p in pairs(player.force.platforms) do if p.index == pid then plat = p; break end end
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

script.on_event(defines.events.on_gui_location_changed, function(event)
  local el = event.element
  local player = game.get_player(event.player_index)
  if not (el and el.valid and player) then return end

  if el.name == UI_NAME then
    local st = ui_state(player.index)
    st.loc = { x = el.location.x, y = el.location.y }
    position_resizer(player)
    update_info_label(player)
    update_debug_markers(player)
    return
  end

  if el.name == RESIZE_HANDLE_NAME then
    local frame = player.gui.screen[UI_NAME]
    if not (frame and frame.valid) then return end

    local fx, fy = (frame.location and frame.location.x) or 0, (frame.location and frame.location.y) or 0
    local hl    = el.location or handle_location_for(player)

    local new_w = math.min(MAX_W, math.max(MIN_W, (hl.x - fx) + RESIZE_SIZE))
    local new_h = math.min(MAX_H, math.max(MIN_H, (hl.y - fy) + RESIZE_SIZE))

    local st = ui_state(player.index)
    st.w, st.h = new_w, new_h

    fix_frame_size(frame, new_w, new_h)

    position_resizer(player)
    update_info_label(player)
    update_debug_markers(player)
    return
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local el = event.element
  local player = game.get_player(event.player_index)
  if not player then return end
  if el and el.name == UI_NAME then
    capture_ui_state(player)
    el.destroy()
    destroy_move_menu(player)
    destroy_rename_menu(player)
    destroy_delete_menu(player)
    local h = player.gui.screen[RESIZE_HANDLE_NAME]
    if h and h.valid then h.destroy() end
    ui_state(player.index).follow = false
    update_debug_markers(player)
  elseif el and (el.name == MOVE_MENU_NAME or el.name == RENAME_MENU_NAME or el.name == DELETE_MENU_NAME) then
    el.destroy()
  end
end)

-- ========= Lifecycle & tick glue =========
script.on_init(function() ensure_global_tables() end)
script.on_configuration_changed(function() ensure_global_tables() end)

script.on_nth_tick(1, function()
  for _, p in pairs(game.connected_players) do
    local st = ui_state(p.index)
    if st.follow then
      local frame = p.gui.screen[UI_NAME]
      if frame and frame.valid then position_resizer(p) end
    end
    update_debug_markers(p)
  end
end)

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
