
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- event_manager object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local event_manager = {}
event_manager.table = EVENT_MANAGER
event_manager.events = nil

local event_manager_mt = { __index = event_manager }
function event_manager:new()
  local events = {}
  return setmetatable({ events = events }, event_manager_mt)
end

------------------------------------------------------------------------------
function event_manager:add_event(event)
  self.events[#self.events+1] = event
end

------------------------------------------------------------------------------
function event_manager:update(dt)
  for i=#self.events,1,-1 do
    local event = self.events[i]
    event:update(dt)
    
    if event.has_finished then
      table.remove(self.events, i)
    end
  end
  
end

------------------------------------------------------------------------------
function event_manager:draw()
end

return event_manager
