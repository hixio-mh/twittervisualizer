
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- bar_chart object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local bar_chart = {}
bar_chart.table = 'bar_chart'
bar_chart.clock = nil
bar_chart.x = nil
bar_chart.y = nil
bar_chart.width = nil           -- width, height of entire widget
bar_chart.height = nil
bar_chart.bbox = nil
bar_chart.data_bbox = nil

-- status
bar_chart.is_displayed = false

-- data area
bar_chart.data_padx = 100         -- padding between data and outside of widget
bar_chart.data_pady = 50
bar_chart.data_x = nil
bar_chart.data_y = nil
bar_chart.data_width = nil
bar_chart.data_height = nil
bar_chart.start_x = nil
bar_chart.end_x = nil
bar_chart.original_start_x = nil
bar_chart.original_end_x = nil
bar_chart.axis_timer = nil

-- bin dimensions
bar_chart.bin_width = 6         -- width of vertical bar
bar_chart.bin_pad = 1           -- padding on each side of bar graphic
bar_chart.bin_draw_width = nil
bar_chart.num_bins = nil
bar_chart.bin_range = nil
bar_chart.bin_vals = nil
bar_chart.bin_timers = nil
bar_chart.bin_max = nil
bar_chart.bin_curve = nil

-- data
bar_chart.hits = nil
bar_chart.original_hits = nil
bar_chart.last_hit_len = 0

-- labels
bar_chart.title_font = font_medium
bar_chart.title = ''
bar_chart.title_highlight = ''
bar_chart.original_title = ''
bar_chart.original_title_highlight = ''
bar_chart.title_x = nil
bar_chart.title_y = nil
bar_chart.highlight_x = nil
bar_chart.highlight_y = nil

bar_chart.pref_xtick_width = 50
bar_chart.pref_ytick_width = 40
bar_chart.xvalues = nil
bar_chart.yvalues = nil
bar_chart.xrange = nil
bar_chart.yrange = nil
bar_chart.xtick_width = nil
bar_chart.ytick_width = nil
bar_chart.xvalue_offset = nil
bar_chart.yvalue_offset = nil
bar_chart.last_bin_max = 1

-- mouse input
bar_chart.hover_idx = nil
bar_chart.mouse_press_idx = nil
bar_chart.select_bbox = nil
bar_chart.select_min = nil
bar_chart.select_max = nil
bar_chart.select_min_time = nil
bar_chart.select_max_time = nil
bar_chart.zoomed_in = false
bar_chart.select_color = {0, 167, 127, 255}
bar_chart.normal_color = C_ORANGE
bar_chart.mouse_x = 0
bar_chart.mouse_y = 0

local bar_chart_mt = { __index = bar_chart }
function bar_chart:new(app, x, y, width, height, start_x, end_x, 
                       hits, bin_curve, title, title_highlight)
  
  local clock = app.real_clock
  local event_manager = app.event_manager
  
  -- data area attributes
  local pad_x, pad_y = bar_chart.data_padx, bar_chart.data_pady
  local data_x = x + pad_x
  local data_y = y + pad_y
  local data_width = width - 2 * pad_x
  local data_height = height - 2 * pad_y
  local axis_timer = timer:new(clock, 0.5)
  
  local bbox = bbox:new(x, y, width, height)
  local data_bbox = bbox:new(data_x, data_y, data_width, data_height)
  local select_bbox = bbox:new(0, 0, 0, data_height)
  
  -- go back to all tweets button
  local rw, rh = 30, 30
  local rx = x + width - rw
  local ry = y
  local back_bbox = bbox:new(rx, ry, rw, rh)
  
  -- reset view button
  local rw, rh = 30, 30
  local rx = x + width - rw
  local ry = y + 45
  local reset_bbox = bbox:new(rx, ry, rw, rh)
  
  local title_font = bar_chart.title_font
  local full_title_width = title_font:getWidth(title..title_highlight)
  local title_width = title_font:getWidth(title)
  local title_x = x + 0.5 * width - 0.5 * full_title_width
  local title_y = y
  local highlight_x = title_x + title_width
  local highlight_y = y
  
  
  return setmetatable({x = x,
                       y = y,
                       width = width,
                       height = height,
                       app = app,
                       bbox = bbox,
                       data_bbox = data_bbox,
                       select_bbox = select_bbox,
                       back_bbox = back_bbox,
                       reset_bbox = reset_bbox,
                       clock = clock,
                       start_x = start_x,
                       end_x = end_x,
                       original_start_x = start_x,
                       original_end_x = end_x,
                       data_x = data_x,
                       data_y = data_y,
                       data_width = data_width,
                       axis_timer = axis_timer,
                       data_height = data_height,
                       hits = hits,
                       original_hits = hits,
                       bin_curve = bin_curve,
                       event_manager = event_manager,
                       title = title,
                       original_title = title,
                       title_highlight = title_highlight,
                       original_title_highlight = title_highlight,
                       title_x = title_x,
                       title_y = title_y,
                       highlight_x = highlight_x,
                       highlight_y = highlight_y}, bar_chart_mt)
end

function bar_chart:set_mouse_position(x, y)
  self.mouse_x = x
  self.mouse_y = y
end

function bar_chart:set_position(x, y)
  local transx = x - self.x
  local transy = y - self.y
  
  self.x = self.x + transx
  self.y = self.y + transy
  
  self.data_x = self.data_x + transx
  self.data_y = self.data_y + transy
end

function bar_chart:init()
  local end_x = self.end_x
  local start_x = self.start_x

  -- bin attributes
  local bwidth = self.bin_width
  local bpad = self.bin_pad
  local bin_draw_width = bwidth - 2 * bpad
  
  -- sort hits into bins
  local hits = self.hits
  local bin_vals, bin_range, bin_max = self:_sort_into_bins(hits, start_x, end_x)
  local num_bins = #bin_vals
  
  -- init bin timers
  bin_timers = {}
  local clock = self.clock
  for i=1,num_bins do
    bin_timers[i] = timer:new(clock, math.random()*0.2 + 0.7)
  end
  
  -- calculate range values
  local end_y = math.max((math.max(bin_max, 1) / bin_range) * 60, 0.001)
  local xrange, xtick_width, xvalues = self:get_range_values(start_x, end_x, 
                                                             self.data_width, 
                                                             self.pref_xtick_width)
  local yrange, ytick_width, yvalues = self:get_range_values(0, end_y, 
                                                             self.data_height, 
                                                             self.pref_ytick_width)
  
  local xvalue_offset = (self.data_width / (end_x - start_x)) * (xvalues[1] - start_x)
  local yvalue_offset = (self.data_height / (end_y)) * yvalues[1]
  
  self.xvalues = xvalues
  self.yvalues = yvalues
  self.xrange = xrange
  self.yrange = yrange
  self.xtick_width = xtick_width
  self.ytick_width = ytick_width
  self.xvalue_offset = xvalue_offset
  self.yvalue_offset = yvalue_offset
                                                             
  self.bin_draw_width = bin_draw_width
  self.num_bins = num_bins
  self.bin_range = bin_range
  self.bin_vals = bin_vals
  self.bin_max = bin_max
  self.last_bin_max = bin_max
  self.bin_timers = bin_timers
  
end

function bar_chart:set_title(title, title_highlight)
  self.title = title
  self.title_highlight = title_highlight
  
  local title_font = bar_chart.title_font
  local full_title_width = title_font:getWidth(title..title_highlight)
  local title_width = title_font:getWidth(title)
  self.title_x = self.x + 0.5 * self.width - 0.5 * full_title_width
  self.title_y = self.y
  self.highlight_x = self.title_x + title_width
  self.highlight_y = self.y
end

function bar_chart:set_hit_data(hit_data)
  self.hits = hit_data
  self.last_hit_len = #hit_data
end

function bar_chart:set_range(min_x , max_x)
  self.start_x = min_x
  self.end_x = max_x
  self.zoomed_in = true
end

function bar_chart:get_range_values(start_val, end_val, px_width, preferred_width)
  local diff = end_val - start_val
  local width = px_width
  local target_width = preferred_width
  local max = 10
  
  local min_error = 10000000
  local choice_range = nil
  local break_loop = false
  for j=-3,max do
    for i=2,0,-1 do
      local range = (10^j) / (2^i)
      local ticks = math.floor(diff / range)
      
      if ticks == 0 then
        break_loop = true
        break
      end
      ticks = diff / range
      
      local tick_width = width / ticks
      local e = math.abs(target_width - tick_width)
      
      if e < min_error then
        min_error = e
        choice_range = range
      end
      
      --print(range, ticks, tick_width, e)
      
    end
    
    if break_loop then
      break
    end
  end
  
  local range = choice_range
  local ticks = math.floor(diff / range)
  local tick_width = width / (diff / range)

  local tick_values = {}
  local start = (math.floor(start_val / range) + 1) * range
  for i=1,ticks+1 do
    tick_values[i] = start + (i-1) * range
  end
  
  return choice_range, tick_width, tick_values
end

function bar_chart:reset_range()
  self.start_x = self.original_start_x
  self.end_x = self.original_end_x
  self.zoomed_in = false
end

function bar_chart:mousepressed(x, y, button)
  
  if button == 'r' then
    self.mouse_press_idx = nil
    self.select_min = nil
    self.select_max = nil
  end

  if button == 'l' then
    local mpos = vector2:new(x, y)
    if self.data_bbox:contains_point(mpos) then
      self.mouse_press_idx = math.floor((x - self.data_x) / self.bin_width) + 1
      if self.mouse_press_idx > self.num_bins then
        self.mouse_press_idx = nil
      end
    end
    
    -- clear selection or view selection
    if self.data_bbox:contains_point(mpos) then
      if self.select_min and self.select_max then
      
        if self.select_bbox:contains_point(mpos) then
          self:set_range(self.select_min_time, self.select_max_time)
          self:display()
          self.mouse_press_idx = nil
          self.select_min = nil
          self.select_max = nil
        end
        
      end
    end
    
    -- press reset button (zoom back to original dimentions)
    if self.zoomed_in and self.reset_bbox:contains_point(mpos) then
      self:reset_range()
      self:display()
    end
    
    -- press back button (set original hits)
    if self.hits ~= self.original_hits and self.back_bbox:contains_point(mpos) then
      self:set_hit_data(self.original_hits)
      self:set_title(self.original_title, self.original_title_highlight)
      self:display()
      
      self.app.twitter_feed:reset_tweet_data()
      
      -- clear selected hashtag in app. Bad workaround!
      if self.app then
        local top = self.app.top_hashtags
        for j=1,#top do
          top[j].selected = false
        end
      end
      
    end
    
  end
end

function bar_chart:mousereleased(x, y, button)
  if button == 'l' then
  
  end
end

function bar_chart:_sort_into_bins(hit_times, start_x, end_x)
  -- find range of bins
  local bwidth = self.bin_width
  local num_bins = math.floor(self.data_width / bwidth)
  local bin_range = (end_x - start_x) / num_bins

  -- only process hits betweet start_x and end_x
  local hits = {}
  local idx = 1
  for i=1,#hit_times do
    local t = hit_times[i]
    if t >= start_x and t <= end_x then
      hits[idx] = t
      idx = idx + 1
    end
  end

  local bin_vals = {}
  for i=1,num_bins do
    bin_vals[i] = 0
  end
  
  local bin_end = start_x + bin_range
  local current_bin = 1
  local count = 0
  local bin_max = 0
  for i=1,#hits do
    t = hits[i]
    
    if t < bin_end then
      count = count + 1
    else                      -- change bin
      bin_vals[current_bin] = count
      if count > bin_max then
        bin_max = count
      end
      
      -- find next bin that value t fits into
      bin_end = bin_end + bin_range
      current_bin = current_bin + 1
      while t > bin_end do
        bin_end = bin_end + bin_range
        current_bin = current_bin + 1
      end
      
      count = 1
    end
  end
  bin_vals[current_bin] = count
  if count > bin_max then
    bin_max = count
  end
  
  return bin_vals, bin_range, bin_max
end

function bar_chart:display()
  self:init()

  local timers = self.bin_timers
  local tstep = 0.002
  for i=1,self.num_bins do
    event:new(self.event_manager, self.clock, 
              {function() timers[i]:start() end, 0}, tstep * i)
  end
  self.axis_timer:start()
  
  self.mouse_press_idx = nil
  self.select_min = nil
  self.select_max = nil
  
  self.is_displayed = true
end

function bar_chart:hide()
  local timers = self.bin_timers
  for i=1,self.num_bins do
    timers[i]:reset()
  end

  self.is_displayed = false
end

------------------------------------------------------------------------------
function bar_chart:update(dt)

  self:_update_new_hits(dt)
  self:_update_mouse_selection(dt)
  
end

function bar_chart:_update_mouse_selection(dt)
  -- check mosue hover
  local mx, my = self.mouse_x, self.mouse_y
  local mpos = vector2:new(mx, my)
  if self.data_bbox:contains_point(mpos) then
    local hover_idx = math.floor((mx - self.data_x) / self.bin_width) + 1
    if hover_idx > self.num_bins then
      hover_idx = self.num_bins
    end
    self.hover_idx = hover_idx
  else
    self.hover_idx = nil
  end
  
  -- check if there is a selection
  select_min = nil
  select_max = nil
  local press_idx = self.mouse_press_idx
  local hover_idx = self.hover_idx
  if press_idx and hover_idx and app.mouse_isdown then
    self.select_min = math.min(press_idx, hover_idx)
    self.select_max = math.max(press_idx, hover_idx)
    
    local sx_min = self.data_x + self.bin_width * (self.select_min - 1)
    local sx_max = self.data_x + self.bin_width * self.select_max
    local swidth = sx_max - sx_min
    local y = self.data_y
    local sbbox = self.select_bbox
    sbbox.x = sx_min
    sbbox.y = y
    sbbox.width = swidth 
    
    self.select_min_time = self.start_x + (self.select_min - 1) * self.bin_range
    self.select_max_time = self.start_x + self.select_max * self.bin_range
  end
  
end

function bar_chart:_update_new_hits(dt)
  -- update chart bins for additional hits
  local hits = self.hits
  if #hits > self.last_hit_len then
    local start_x, end_x = self.start_x, self.end_x
    local bin_range = self.bin_range
  
    local num_new = #hits - self.last_hit_len
    local bin_vals = self.bin_vals
    for i=#hits,#hits-num_new+1,-1 do
      local t = hits[i]
      
      -- find which bin this hit belongs to
      if t >= start_x and t < end_x then
        local bin_idx = math.floor((t - start_x) / bin_range) + 1
        bin_vals[bin_idx] = bin_vals[bin_idx] + 1
        if bin_vals[bin_idx] > self.bin_max then
          self.bin_max = bin_vals[bin_idx]
        end
      end
      
    end
  end
  
  self.last_hit_len = #hits
  
end

------------------------------------------------------------------------------
function bar_chart:draw()

  if not self.is_displayed then
    return
  end
  

  lg.setColor(C_DARKER_GREY)
  lg.rectangle("line", self.x, self.y, self.width, self.height)
  --lg.rectangle("line", self.data_x, self.data_y, 
  --                     self.data_width, self.data_height)

             
  -- draw bars                     
  local height = self.data_height
  local pad = self.bin_pad
  local width = self.bin_draw_width
  local bsize = self.bin_width
  local x = self.data_x + pad
  local y = self.data_y + self.data_height - height
  lg.setColor(C_ORANGE)
  
  local timers = self.bin_timers
  local curve = self.bin_curve
  local hover_idx = self.hover_idx
  local select_min = self.select_min
  local select_max = self.select_max
  for i=1,self.num_bins do
    local bheight = (self.bin_vals[i] / self.bin_max) * height * curve:get(timers[i]:progress())
    local y = self.data_y + self.data_height - bheight
    
    -- color on hover and selection
    if hover_idx and i == hover_idx then
      lg.setColor(self.select_color)
    end
    if select_min and select_max and i >= select_min and i <= select_max then
      lg.setColor(self.select_color)
    end
    
    lg.rectangle('fill', x + (i - 1) * bsize, y, width, bheight)
    
    -- these statements to revert to original color if changed due to hover
    -- or selection. Want to minimize calls to selectColor for efficiency
    if hover_idx and i == hover_idx then
      lg.setColor(self.normal_color)
    end
    if select_min and select_max and i >= select_min and i <= select_max then
      lg.setColor(self.normal_color)
    end
    
  end
  
  -- draw axis'
  local axis_timer = self.axis_timer
  local xpad = 3
  local progress = curve:get(axis_timer:progress())
  local h = self.data_y + height * (1 - progress)
  local w = self.data_x + self.data_width * progress
  lg.setColor(C_GREEN)
  lg.setLine(3)
  lg.line(self.data_x-xpad, h, self.data_x-xpad, self.data_y + height)
  lg.line(self.data_x-xpad, self.data_y + height, 
          w, self.data_y + height)
          
  -- draw axis values
  local xvalues = self.xvalues
  local xw = self.xtick_width
  local offx = self.xvalue_offset
  local x = self.data_x
  local y = self.data_y + self.data_height
  
  lg.setColor(0, 0, 0, 255)
  lg.setPoint(5, "smooth")
  lg.setFont(font_smallest)
  local day = self.app.start_day
  local month = self.app.start_month
  local hour = self.app.start_hour
  local minute = self.app.start_minute
  local second = self.app.start_second
  for i=1,#xvalues do
    local start_time = self.app.start_time
    local val = xvalues[i] - start_time
    
    local d, h, m, s = 0, 0, 0, 0
    
    s = second + val
    if s >= 60 then
      m = m + math.floor(s / 60)
      s = s % 60
    end
    
    m = minute + m
    if m >= 60 then
      h = h + math.floor(m / 60)
      m = m % 60
    end
    
    h = hour + h
    if h >= 24 then
      d = d + math.floor(h / 24)
      h = h % 24
    end
    d = day + d
    
    val = string.format("%02d:%02d:%02d", h, m ,s)
    
    local x, y = x + offx + (i-1) * xw, y + 10
    lg.point(x, y - 5)
    lg.print(val, x, y, 0.1 * 2 * math.pi)
  end
  
  
  if self.last_bin_max ~= self.bin_max then
    local end_y = math.max((math.max(self.bin_max, 1) / self.bin_range) * 60, 0.001)
    local yrange, 
    ytick_width, 
    yvalues = self:get_range_values(0, end_y, 
                                       self.data_height, self.pref_ytick_width)
    
    local yvalue_offset = (self.data_height / end_y) * yvalues[1]
    
    self.yvalues = yvalues
    self.yrange = yrange
    self.ytick_width = ytick_width
    self.yvalue_offset = yvalue_offset
  end
  self.last_bin_max = self.bin_max
  
  local yvalues = self.yvalues
  local yw = self.ytick_width
  local offy = self.yvalue_offset
  lg.print(0, x - 25, y - 10)
  lg.point(x - 10, y - 2)
  for i=1,#yvalues do
    local val = yvalues[i]
    local x, y = x, y - offy - (i-1) * yw
    local offsetx = font_smallest:getWidth(tostring(val))
    lg.point(x - 10, y)
    lg.print(val, x - offsetx - 15, y - 7)
  end
  
  -- selection axis
  if self.select_min and self.select_max then
    local minx = self.select_bbox.x
    local maxx = self.select_bbox.x + self.select_bbox.width
    lg.setColor(16,134,8,255)
    lg.line(minx, self.data_y + height, maxx, self.data_y + height)
            
    -- expand icon
    local cx = 0.5 * (minx + maxx)
    local cy = 0.5 * (2 * self.data_y + self.data_height) 
    local r = 8
    
    local mpos = vector2:new(self.app.mx, self.app.my)
    if self.select_bbox:contains_point(mpos) then
      lg.setColor(C_DARK_GREEN)
    else
      lg.setColor(0, 119, 78, 255)
    end
    
    lg.setLine(2)
    lg.circle('line', cx, cy, 0.75 * r)
    lg.line(cx - 2*r, cy, cx + 2 * r, cy)
    lg.line(cx, cy - r, cx, cy + r)
    lg.line(cx - 2*r, cy, cx - 1.5 * r, cy - 0.5 * r)
    lg.line(cx - 2*r, cy, cx - 1.5 * r, cy + 0.5 * r)
    lg.line(cx + 2*r, cy, cx + 1.5 * r, cy - 0.5 * r)
    lg.line(cx + 2*r, cy, cx + 1.5 * r, cy + 0.5 * r)
  end
  
  -- draw reset icon
  if self.zoomed_in then
    local bbox = self.reset_bbox
    local cx = 0.5 * (2 * bbox.x + bbox.width)
    local cy = 0.5 * (2 * bbox.y + bbox.height)
    local r = 8
    
    local mpos = vector2:new(self.app.mx, self.app.my)
    local on_button = bbox:contains_point(mpos)
    if on_button then
      lg.setColor(C_GREEN)
    else
      lg.setColor(C_DARK_GREEN)
    end
    
    lg.setLine(1)
    lg.circle('line', cx, cy, 0.75 * r)
    lg.line(cx - 2*r, cy, cx + 2 * r, cy)
    lg.line(cx, cy - r, cx, cy + r)
    lg.line(cx - 2*r, cy, cx - 1.5 * r, cy - 0.5 * r)
    lg.line(cx - 2*r, cy, cx - 1.5 * r, cy + 0.5 * r)
    lg.line(cx + 2*r, cy, cx + 1.5 * r, cy - 0.5 * r)
    lg.line(cx + 2*r, cy, cx + 1.5 * r, cy + 0.5 * r)
    lg.rectangle('line', bbox.x, bbox.y, bbox.width, bbox.height)
    
    lg.setLine(2)
    if on_button then
      lg.setColor(C_RED)
    else
      lg.setColor(C_DARK_RED)
    end
    lg.line(bbox.x, bbox.y, bbox.x + bbox.width, bbox.y + bbox.height)
  end
          
  -- Draw back to original hits button
  if self.hits ~= self.original_hits then
    local bbox = self.back_bbox
    local cx = 0.5 * (2 * bbox.x + bbox.width)
    local cy = 0.5 * (2 * bbox.y + bbox.height)
    local r = 10
    local mpos = vector2:new(self.mouse_x, self.mouse_y)
    
    if bbox:contains_point(mpos) then
      lg.setColor(0, 150, 0, 255)
    else
      lg.setColor(C_DARK_GREEN)
    end
    lg.setLine(1)
    lg.rectangle('line', bbox.x, bbox.y, bbox.width, bbox.height)
    lg.line(cx + 0.75 * r, cy + 0.5 * r, cx + 0.75 * r, cy - 0.5 * r)
    lg.line(cx - 0.5 * r, cy - 0.5*r, cx + 0.75 * r, cy - 0.5*r)
    lg.line(cx - 0.5 * r, cy - 0.5*r, cx, cy - 0.5*r - 0.5 * r)
    lg.line(cx - 0.5 * r, cy - 0.5*r, cx, cy - 0.5*r + 0.5 * r)
    
  end
  
  -- draw title
  local curve = self.bin_curve
  local timer = self.axis_timer
  local progress = curve:get(timer:progress())
  lg.setFont(self.title_font)
  lg.setColor(0, 20, 0, progress * 255)
  lg.print(self.title, self.title_x, self.title_y)
  
  lg.setColor(0, 167, 127, progress * 255)
  lg.print(self.title_highlight, self.highlight_x, self.highlight_y)
  
  lg.setLine(1)
end

return bar_chart












