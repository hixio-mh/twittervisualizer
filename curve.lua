
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- curve object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local curve = {}
curve.table = CURVE
curve.length = nil
curve.inv_length = nil
curve.values = nil

-- points: table of vector 2's starting at x=0, ending at x=1
--         x values listed in ascending order
-- num_idx: number of indices to generate. Higher -> more precision
local curve_mt = { __index = curve }
function curve:new(points, num_idx)
	-- generate splines
	local spline = cubic_spline:new(points)
	local step = 1 / num_idx
	local xval = 0
	local values = {}
	for i=1,num_idx do
		local y = spline:get_val(xval)
		xval = xval + step
		
		values[i] = {x = xval, y = y}
	end

  return setmetatable({ values = values,
                        length = num_idx,
                        inv_length = step}, curve_mt)
end

function curve:get(x)
	local idx = math.floor(x * self.length)
	if idx > self.length then
		idx = self.length
	elseif idx <= 0 then
		idx = 1
	end
	
	return self.values[idx].y
end

------------------------------------------------------------------------------
function curve:update(dt)
end

------------------------------------------------------------------------------
function curve:draw()
end

return curve



