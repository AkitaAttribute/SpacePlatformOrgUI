-- luacheck: globals global script defines log serpent

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"
local HEADER_W_DEC = "sp-size-w-dec"
local HEADER_W_INC = "sp-size-w-inc"
local HEADER_H_DEC = "sp-size-h-dec"
local HEADER_H_INC = "sp-size-h-inc"
local SIZE_INC = 40
log("[sp-ui] global type: " .. tostring(type(global)))

local function ui_state(pi)
  -- Always use the engine-provided global; protect against accidental shadowing
  local G = rawget(_G, "global")
  if not G then
    -- Recover from shadowing: reattach a table so we don't crash
    G = {}
    _G.global = G
    log("[sp-ui] WARNING: 'global' was nil; recreated temporary table.")
  end

  G.spui = G.spui or {}
  local st = G.spui[pi]
  if not st then
    st = { w = 440, h = 528 }
    G.spui[pi] = st
  end
  return st
end

local function collect_platforms(force)
  local entries = {}
  if not (force and force.valid and force.platforms) then return entries end
  for _, p in pairs(force.platforms) do
    if p and p.valid then
      entries[#entries + 1] = {
        id = p.index,
        caption = p.name or ("Platform " .. p.index),
        surface_name = p.surface and p.surface.name or nil
      }
    end
  end
  return entries
end

local function safe_sprite_button(parent, name, sprite, tooltip)
  local ok, elem = pcall(function()
    return parent.add{
      type   = "sprite-button",
      name   = name,
      sprite = sprite,
      style  = "frame_action_button",
      tooltip = tooltip
    }
  end)
  if ok and elem then return elem end
  -- Fallback so missing sprites never crash the mod
  return parent.add{
    type = "button",
    name = name,
    caption = tooltip or name
  }
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
  drag.drag_target = frame   -- IMPORTANT: makes the whole frame draggable

  -- Row 2: left-aligned resize controls
  local controls = header.add{ type = "flow", direction = "horizontal", name = "sp_controls" }
  controls.style.horizontal_spacing = 2
  safe_sprite_button(controls, HEADER_W_DEC, "utility/left_arrow",  "Narrower")
  safe_sprite_button(controls, HEADER_W_INC, "utility/right_arrow", "Wider")
  safe_sprite_button(controls, HEADER_H_DEC, "utility/down_arrow",  "Shorter")
  safe_sprite_button(controls, HEADER_H_INC, "utility/up_arrow",    "Taller")
  -- Collect platforms from the force
  local entries = collect_platforms(player.force)  -- sequential array of {id, caption}
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
    local b = list.add{
      type = "button",
      name = BUTTON_PREFIX .. tostring(entry.id),
      caption = entry.caption,
      tags = { platform_index = entry.id },
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
  -- Resolve a safe position without touching plat.position (it doesn't exist)
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
  local st = ui_state(player.index)

  local delta_w, delta_h
  if element.name == HEADER_W_DEC or element.name == HEADER_W_INC then
    delta_w = (element.name == HEADER_W_DEC) and -SIZE_INC or SIZE_INC
  elseif element.name == HEADER_H_DEC or element.name == HEADER_H_INC then
    delta_h = (element.name == HEADER_H_DEC) and -SIZE_INC or SIZE_INC
  else
    -- platform click logic below
    if not element.name or element.name:sub(1, #BUTTON_PREFIX) ~= BUTTON_PREFIX then return end
    local pid = element.tags and element.tags.platform_index
        or tonumber(element.name:sub(#BUTTON_PREFIX + 1))
    if not pid then return end
    open_platform_view(player, pid)
    return
  end

  st.w = math.max(320, math.min(900, st.w + (delta_w or 0)))
  st.h = math.max(240, math.min(900, st.h + (delta_h or 0)))
  local prefs = global.spui
  prefs[player.index] = st
  rebuild_ui(player)
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element
  if element and element.name == UI_NAME then
    element.destroy()
  end
end)

script.on_init(function()
  global.spui = global.spui or {}
end)

script.on_configuration_changed(function()
  global.spui = global.spui or {}
end)
