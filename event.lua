--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- event object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local event = {}
event.table_name = 'event'
event.delay = nil
event.actions = nil
event.current_action = 1
event.mode = nil
event.has_finished = false
event.delay_timer = nil
event.max_repetitions = nil
event.repetitions = 1

local event_mt = { __index = event }
function event:new(event_manager, clock, event_list, delay, mode, repetitions)
  delay = delay or 0
  mode = mode or 'once'
  
  local actions = {}
  for i=1,#event_list,2 do
    local func = event_list[i]
    local time = event_list[i+1]
    local timer = timer:new(clock, time)
    
    local action = {}
    action.func = func
    action.timer = timer
    actions[#actions+1] = action
  end
  
  delay_timer = timer:new(clock, delay)
  delay_timer:start()
  
  local event = setmetatable({ actions = actions,
                        delay = delay,
                        mode = mode,
                        delay_timer = delay_timer,
                        max_repetitions = repetitions}, event_mt)
  
  event_manager:add_event(event)           
  return event
end

------------------------------------------------------------------------------
function event:update(dt)
  if self.delay_timer:progress() < 1 or self.has_finished then
    return
  end
  
  local current_action = self.actions[self.current_action]
  local progress = current_action.timer:progress()
  if progress == 0 then
    current_action.timer:start()
    current_action.func()
    
  elseif progress == 1 then
    self.actions[self.current_action].timer:reset()
    self.current_action = self.current_action + 1
    
    local is_last_action = self.current_action > #self.actions
    if     is_last_action and self.mode == 'once' then
      self.has_finished = true
      
    elseif is_last_action and self.mode == 'repeat' then
      self.repetitions = self.repetitions + 1
      if self.max_repetitions ~= nil and self.repetitions > self.max_repetitions then
        self.has_finished = true
      end
      self.current_action = 1
    end
    
  end
  
end

------------------------------------------------------------------------------
function event:cancel()
  self.has_finished = true
end

------------------------------------------------------------------------------
function event:draw()
end

return event
