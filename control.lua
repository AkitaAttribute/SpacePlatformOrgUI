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

  -- Collect platforms from the force
  local entries = collect_platforms(player.force)  -- sequential array of {id, caption}
  log("UI: rendering " .. tostring(#entries) .. " platforms")

  -- Scroll pane + vertical list container
  local scroll = frame.add{ type = "scroll-pane", name = "platform_scroll" }
  scroll.style.maximal_height = 400
  scroll.style.minimal_width = 250
  scroll.style.vertically_stretchable = true
  scroll.style.horizontally_stretchable = true

  local list = scroll.add{ type = "flow", name = "platform_list", direction = "vertical" }

  if #entries == 0 then
    list.add{ type = "label", caption = {"gui.space-platforms-org-ui-no-platforms"} }
    return
  end

  for i, entry in ipairs(entries) do
    log("UI: add button #" .. tostring(i) .. " id=" .. tostring(entry.id) .. " caption=" .. tostring(entry.caption))
    local btn = list.add{
      type = "button",
      name = BUTTON_PREFIX .. entry.id,
      caption = entry.caption,
      tags = { platform_index = entry.id }
    }
    if btn and btn.valid then
      -- Give it some guaranteed footprint so it is visible
      btn.style.minimal_width = 200
      btn.style.top_padding = 2
      btn.style.bottom_padding = 2
    else
      log("UI: failed to create button for id=" .. tostring(entry.id))
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
  if not element.name or element.name:sub(1, #BUTTON_PREFIX) ~= BUTTON_PREFIX then return end

  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  local idx = element.tags and element.tags.platform_index
  if not idx then return end

  local plat
  for _, p in pairs(player.force.platforms or {}) do
    if p and p.valid and p.index == idx then plat = p; break end
  end
  if plat and plat.valid then
    pcall(function() player.opened = plat end)
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element
  if element and element.valid and element.name == UI_NAME then
    element.destroy()
  end
end)
