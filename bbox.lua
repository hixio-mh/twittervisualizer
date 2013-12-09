
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- bbox object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local bbox = {}
bbox.table = BBOX
bbox.x = nil
bbox.y = nil
bbox.width = nil
bbox.height = nil

local bbox_mt = { __index = bbox }
function bbox:new(x, y, width, height)
  return setmetatable({ x = x,
                        y = y,
                        width = width, 
                        height = height }, bbox_mt)
end

------------------------------------------------------------------------------
function bbox:get_x() return self.x end
function bbox:get_y() return self.y end
function bbox:get_width() return self.width end
function bbox:get_height() return self.height end

------------------------------------------------------------------------------
function bbox:intersects(B)
  local A = self
  
  local Ahw, Bhw = 0.5 * A.width, 0.5 * B.width
  local inter_x = math.abs(B.x - A.x + Bhw - Ahw) < Ahw + Bhw
  
  if inter_x then
    local Ahh, Bhh = 0.5 * A.height, 0.5 * B.height
    return math.abs(B.y - A.y + Bhh - Ahh) < Ahh + Bhh
  else
    return false
  end
end

------------------------------------------------------------------------------
function bbox:contains_point(p)
  local x, y = self.x, self.y
  return (p.x > x and p.x < x + self.width) and 
         (p.y > y and p.y < y + self.height)
end

------------------------------------------------------------------------------
function bbox:contains(B)
  local Ax, Ay = self.x, self.y
  local Bx, By = B.x, B.y
  return (Bx > Ax) and (Bx + B.width < Ax + self.width) and
         (By > Ay) and (By + B.height < Ay + self.height)
end

------------------------------------------------------------------------------
function bbox:draw(mode)
  if mode == 'fill' then
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
  end
  love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
end

return bbox








