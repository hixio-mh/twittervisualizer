--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- master_timer object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local master_timer = {}
master_timer.current_time = 0
master_timer.has_started = false
master_timer.time_scale = 1


local master_timer_mt = { __index = master_timer }
function master_timer:new()
  
  return setmetatable({ }, master_timer_mt)
end



------------------------------------------------------------------------------
function master_timer:start()
  self.has_started = true
end

------------------------------------------------------------------------------
function master_timer:stop()
  self.has_started = false
end

function master_timer:set_time(time)
  self.current_time = time
end

function master_timer:set_time_scale(scale)
  self.time_scale = scale
end

------------------------------------------------------------------------------
function master_timer:update(dt)
  self.current_time = self.current_time + self.time_scale * dt
end

function master_timer:get_time()
  return self.current_time
end

return master_timer
