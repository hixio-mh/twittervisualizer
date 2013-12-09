--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- timer object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local timer = {}
timer.table = TIMER
timer.length = 0
timer.start_time = nil
timer.master = nil

local timer_mt = { __index = timer }
function timer:new(master_timer, length)      -- length in seconds
  length = length or 0
  
  return setmetatable({length = length,
                       master = master_timer}, timer_mt)
end


------------------------------------------------------------------------------
function timer:start()
  self.start_time = self.master:get_time()
end


------------------------------------------------------------------------------
function timer:set_length(length)
  self.length = length
end


------------------------------------------------------------------------------
-- returns elapsed time in milliseconds
-- returns nil if timer has not started
function timer:time_elapsed()
  if self.start_time == nil then
    return nil
  end
  return self.master:get_time() - self.start_time
end


------------------------------------------------------------------------------
-- returns the progress from the start of the timer
-- returns nil if timer has not started
-- t = 0    no time passed
-- t = 0.5  half of the time has passed
-- t = 1.0  full time has passed
function timer:progress()
  if self.start_time == nil then
    return 0
  end
  local current_progress = self:time_elapsed()/self.length
  if current_progress >= 1 then
    current_progress = 1
  end
  
  return current_progress
end


------------------------------------------------------------------------------
-- returns whether the timer is initialized and running (has not finished)
function timer:isrunning()
  if self.start_time == nil or self:isfinished() then
    return false
  end
  
  return true
end

------------------------------------------------------------------------------
function timer:reset()
  self.start_time = nil
end


------------------------------------------------------------------------------
-- returns whether time timer has finished
function timer:isfinished()

  if self:time_elapsed() <= self.length then
    return false
  end
  
  return true
end


return timer
