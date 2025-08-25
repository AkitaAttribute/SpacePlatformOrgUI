-- luacheck: globals script defines log

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"

local function collect_platforms(force)
  local entries = {}
  if not (force and force.valid and force.platforms) then return entries end
  for _, p in pairs(force.platforms) do
    if p and p.valid then
      table.insert(entries, { id = p.index, caption = p.name or ("Platform " .. tostring(p.index)) })
    end
  end
  return entries
end

local function build_platform_ui(player)
  local frame = player.gui.screen.add{
    type = "frame",
    name = UI_NAME,
    caption = {"gui.space-platforms-org-ui-title"},
    direction = "vertical"
  }
  frame.auto_center = true
  frame.style.minimal_width  = 380
  frame.style.minimal_height = 420

  -- Collect platforms from the force
  local entries = collect_platforms(player.force)  -- sequential array of {id, caption}
  log("UI: rendering " .. tostring(#entries) .. " platforms")

  -- Scroll pane + vertical list container
  local scroll = frame.add{ type = "scroll-pane", name = "platform_scroll" }
  scroll.style.vertically_stretchable   = true
  scroll.style.horizontally_stretchable = true
  scroll.style.minimal_width  = 360
  scroll.style.minimal_height = 360

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

script.on_event("space-platform-org-ui-toggle", function(event)
  local player = game.get_player(event.player_index)
  if player then
    toggle_platform_ui(player)
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid) then return end
  if not (element.name and element.name:sub(1, #BUTTON_PREFIX) == BUTTON_PREFIX) then return end

  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  local idx = element.tags and element.tags.platform_index
  if not idx then return end

  local plat
  for _, p in pairs(player.force.platforms or {}) do
    if p and p.valid and p.index == idx then plat = p; break end
  end
  local surf = plat and plat.valid and plat.surface
  if not surf then return end

  -- Try the map view first (preferred), then fall back to zoom_to_world
  local ok = pcall(function()
    player.open_map{ position = {0, 0}, surface = surf, scale = 1 }
  end)
  if not ok then
    pcall(function()
      player.zoom_to_world({0, 0}, 0.5, surf)
    end)
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element
  if element and element.valid and element.name == UI_NAME then
    element.destroy()
  end
end)
