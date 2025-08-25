-- luacheck: globals script defines log

local UI_NAME = "space-platform-org-ui"
local BUTTON_PREFIX = "sp-ui-btn-"

local function collect_platforms(force)
  local entries = {}
  local ok_list, list = pcall(function()
    return force and force.platforms
  end)
  if ok_list and list then
    for _, platform in pairs(list) do
      local ok_valid, valid = pcall(function()
        return platform.valid
      end)
      if ok_valid and valid then
        local ok_index, index = pcall(function()
          return platform.index
        end)
        if ok_index and index then
          local caption = "Platform " .. index
          local ok_name, name = pcall(function()
            return platform.name
          end)
          if ok_name and type(name) == "string" and name ~= "" then
            caption = name
          end
          table.insert(entries, { id = index, caption = caption })
        end
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

  local platforms = collect_platforms(player.force)
  log("platform_count=" .. tostring(#platforms))
  if #platforms == 0 then
    frame.add{
      type = "label",
      caption = "No platforms found"
    }
    return
  end

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

  for _, entry in pairs(platforms) do
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
    local index = tags and tags.platform_index
    if index then
      local ok_list, list = pcall(function()
        return player.force.platforms
      end)
      local platform = ok_list and list and list[index]
      local ok_valid = false
      if platform then
        ok_valid = pcall(function()
          return platform.valid
        end)
      end
      if platform and ok_valid and platform.valid then
        pcall(function() player.opened = platform end)
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
