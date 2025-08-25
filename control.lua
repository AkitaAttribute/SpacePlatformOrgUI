-- luacheck: globals script defines log

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"

local function collect_platforms(force)
  local entries = {}
  local ok_list, list = pcall(function()
    return force and force.platforms
  end)
  if ok_list and list then
    for _, p in pairs(list) do
      local ok_valid, valid = pcall(function()
        return p.valid
      end)
      local ok_index, index = pcall(function()
        return p.index
      end)
      if ok_valid and valid and ok_index and index then
        local name
        local ok_name, n = pcall(function()
          return p.name
        end)
        if ok_name and type(n) == "string" and n ~= "" then
          name = n
        end
        table.insert(entries, {
          id = index,
          caption = name or ("Platform " .. tostring(index))
        })
      end
    end
  end
  return entries
end


local function build_platform_ui(player)
  local frame = player.gui.screen.add{
    type = "frame",
    name = UI_NAME,
    caption = {"gui.space-platform-org-ui-title"},
    direction = "vertical"
  }
  frame.auto_center = true

  local entries = collect_platforms(player.force)

  local scroll = frame.add{
    type = "scroll-pane",
    name = "platform_scroll"
  }
  scroll.style.maximal_height = 400
  scroll.style.minimal_width = 250
  scroll.style.vertically_stretchable = true
  scroll.style.horizontally_stretchable = true

  local list = scroll.add{
    type = "flow",
    name = "list",
    direction = "vertical"
  }

  log("UI: rendering " .. tostring(#entries) .. " platforms")

  if #entries == 0 then
    list.add{
      type = "label",
      caption = "No platforms found"
    }
    return
  end

  for _, entry in ipairs(entries) do
    list.add{
      type = "button",
      name = BUTTON_PREFIX .. entry.id,
      caption = entry.caption,
      tags = { platform_index = entry.id }
    }
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
  local player = game.get_player(event.player_index)
  if not (element and element.valid and player) then return end

  if string.sub(element.name, 1, #BUTTON_PREFIX) == BUTTON_PREFIX then
    local tags = element.tags
    local idx = tags and tags.platform_index
    if idx then
      local plat
      for _, p in pairs(player.force.platforms or {}) do
        if p and p.valid and p.index == idx then
          plat = p
          break
        end
      end
      if plat and plat.valid then
        pcall(function() player.opened = plat end)
      end
      local ui = player.gui.screen[UI_NAME]
      if ui and ui.valid then ui.destroy() end
    end
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element
  if element and element.valid and element.name == UI_NAME then
    element.destroy()
  end
end)
