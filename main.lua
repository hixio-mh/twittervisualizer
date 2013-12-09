lg = love.graphics

function love.keypressed(key)
  
  if key == 'escape' then
    love.event.push('quit')
  end
  
  if key == 'r' then
    app.chart:reset_range()
    app.chart:display()
  end
  
  if key == 's' then
    app.chart:display()
  end
  
  if key == 'h' then
    app.chart:hide()
  end
  
  if key == 't' then
    app.chart:set_hit_data(app.hits)
    app.chart:display()
  end
  
  
  if key == 'k' then
    local balls = objects.balls
    
    local x = 0.5 * SCR_WIDTH + math.random(25)
    local y = 0.5 * SCR_HEIGHT + math.random(25)
    local radius = math.random(45, 75)
    local color = math.random(190)
    
    local ball = {}
    ball.body = love.physics.newBody(world, x, y, "dynamic")
    ball.shape = love.physics.newCircleShape(radius)
    ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
    ball.color = {color, color, 255, 255}
    
    balls[#balls+1] = ball
  end
  
  if key == 's' then
    objects.timer:start()
  end
  
  if key == 'q' then
    DISPLAY_HASHTAG = nil
  end
end

function love.mousepressed(x, y, button)
  app:mousepressed(x, y, button)
  
  if SELECTED_BALL then
    local ball = SELECTED_BALL
    local hashtag = ball.tag
    DISPLAY_HASHTAG = hashtag
  end
end

function love.mousereleased(x, y, button)
  app:mousereleased(x, y, button)
end

function init_visuals()
  local timer = timer:new(master_timer, TIME)

  local data = app.archive_data
  love.physics.setMeter(64)
  world = love.physics.newWorld(0, 0, true) 
  objects = {}
  local balls = {}
  
  -- find average max radius
  local max = 0
  for i=1,#data do
    if data[i].max > max then
      max = data[i].max
    end
  end

  for i=1,#data do
    
    local tag = data[i].hashtag
    local spline = data[i].spline
    
    local pad = 300
    local x = math.random(pad, SCR_WIDTH - pad)
    local y = math.random(pad, SCR_HEIGHT - pad)
    
    local max_radius = MAX_RADIUS
    local radius = (spline:get_val(0) / max) * max_radius
    local ball_radius = radius
    if radius <= 0 then
      ball_radius = 1
    end
    
     
    local g = GRADIENT
    local r = radius / max_radius
    if r < 0 then r = 0 end
    if r > 1 then r = 1 end
    local idx = math.floor(r * #g)
    if idx == 0 then idx = 1 end
    local color = g[idx]
    
    local ball = {}
    ball.body = love.physics.newBody(world, x, y, "dynamic")
    ball.shape = love.physics.newCircleShape(ball_radius)
    ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
    ball.color = {color, color, 255, 255}
    ball.tag = tag
    ball.spline = spline
    ball.max = max
    ball.max_radius = max_radius
    ball.color = color
    
    balls[#balls+1] = ball
  end
  objects.balls = balls
  
  objects.timer = timer
  objects.timer:start()
end

function love.load()

  ARGS = arg
  DIRECTORY = arg[2] or '14-oct-2013/'
  SCR_WIDTH  = tonumber(arg[3] or 1400)
  SCR_HEIGHT = tonumber(arg[4] or 900)
  COMMON_WORDS = require('common_words')
  DATA_INITIALIZED = false
  TIME = tonumber(arg[5] or 210)
  GRADIENT = require('gradient1')
  SELECTED_BALL = nil
  DISPLAY_HASHTAG = nil
  MAX_RADIUS = arg[6] or 25000
  lg.setMode(SCR_WIDTH, SCR_HEIGHT, false, true)
  
  -- colors
  -- note: color names no longer represent the colors that they actually are
  C_ORANGE = {0, 101, 255, 255}
  C_DARK_GREY = {235,235,244,255}
  C_DARKER_GREY = {220, 220, 220,255}
  C_GREEN = {0, 20, 0, 255}
  C_DARK_GREEN = {0, 0, 0, 255}
  C_RED = {223, 10, 10, 255}
  C_DARK_RED = {141, 6, 6, 255}
  lg.setBackgroundColor(C_DARK_GREY)
  
  -- fonts
  font_large = lg.newFont('fonts/monofonto.ttf', 36)
  font_medium = lg.newFont('fonts/monofonto.ttf', 26)
  font_small = lg.newFont('fonts/monofonto.ttf', 20)
  font_smallest = lg.newFont('fonts/chunkfive.ttf', 15)
  font_text = lg.newFont('fonts/courier.ttf', 12)
  
  
  -- find data files
  local dir = DIRECTORY
  print(dir)
  if string.sub(dir,1,1) == "/" then
    dir = string.sub(dir, 2, #dir)
  end
  if string.sub(dir, #dir,#dir) == "/" then
    dir = string.sub(dir, 1, #dir-1)
  end
  
  
  files = love.filesystem.enumerate("/"..dir)
  if #files == 0 then
    print("Error: no data files found in directory: "..dir)
    love.event.push('quit')
    return
  end
  
  data_files = {}
  for _,f in ipairs(files) do
    local prefix = string.sub(f, 1, 5)
    if prefix == 'data-' then
      local fileno = tonumber(string.sub(f, 6, 8))
      data_files[fileno + 1] = dir.."/"..string.sub(f, 1, 8)
    end
  end

  print("DATA FILES: ")
  for _,filename in ipairs(data_files) do
    print("", filename)
  end
  
  
  -- load modules
  master_timer = require('master_timer')
  timer = require('timer')
  vector2 = require('vector2')
  cubic_spline = require('cubic_spline')
  curve = require('curve')
  bbox = require('bbox')
  gui_slider = require('gui_slider')
  bar_chart = require('bar_chart')
  twitter_feed = require('twitter_feed')
  event = require('event')
  event_manager = require('event_manager')
  hashtag = require('hashtag')
  app = require('app')
  
  app = app:new(data_files)
  
  master_timer = master_timer:new()
end



function get_time(t)
  local start_time = app.start_time
  local end_time = app.end_time
  local current_time = start_time + t * (end_time-start_time)
  local val = current_time - start_time
  
  local day = app.start_day
  local month = app.start_month
  local hour = app.start_hour
  local minute = app.start_minute
  local second = app.start_second
  
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
  
  return string.format("%s-%s-2013 %02d:%02d:%02d (GMT)", d, month, h, m ,s)
end


local t = 0
function love.update(dt)
  master_timer:update(dt)
  if DISPLAY_HASHTAG then
    master_timer:set_time_scale(0)
  else
    master_timer:set_time_scale(1)
  end
  
  if love.keyboard.isDown('w') then
    master_timer:set_time_scale(0)
  end
  
  if love.keyboard.isDown('e') then
    master_timer:set_time_scale(50)
  end

  if not DATA_INITIALIZED then
    dt = 1/60
    app:update(dt)
  end
  
  if DATA_INITIALIZED then
    
  
    t = t + dt
    world:update(dt)
    local timer = objects.timer
    local progress = timer:progress()
  
    local balls = objects.balls
    for i=1,#balls do
      local ball = balls[i]
      
      local max = ball.max
      local max_radius = ball.max_radius
      local radius = (ball.spline:get_val(progress) / max) * max_radius
      local ball_radius = math.sqrt(radius)
      if radius <= 0 then
        ball_radius = 1
      end
      
      if ball_radius > 5 then
        local shape = ball.shape
        shape:setRadius(ball_radius)
        
        ball.fixture:destroy()
        ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
      end
      
      local g = GRADIENT
      local r = radius / max_radius
      if r < 0 then r = 0 end
      if r > 1 then r = 1 end
      local idx = math.floor(r * #g)
      if idx == 0 then idx = 1 end
      ball.color = g[idx]

      local strength = 5
      local ratio = 2
      local center = vector2:new(0.5 * SCR_WIDTH, 0.5 * SCR_HEIGHT)
      local pos = vector2:new(ball.body:getX(), ball.body:getY())
      local force = (center - pos):normalize() * strength
      --ball.body:applyForce(force.x / ratio, force.y)
      ball.body:setLinearVelocity( force.x, force.y )
      
    end
    
    -- update mouse hover
    local mpos = vector2:new(love.mouse.getPosition())
    local balls = objects.balls
    SELECTED_BALL = nil
    for i=1,#balls do
      local ball = balls[i]
      local r = ball.shape:getRadius()
      local pos = vector2:new(ball.body:getX(), ball.body:getY())
      if vector2:dist_sq(mpos, pos) < r * r then
        SELECTED_BALL = ball
        break
      end
    end
    
  end
  
end

function love.draw()
  lg.setBackgroundColor(255, 255, 255, 255)
  
  lg.setLine(1, 'smooth')
  if DATA_INITIALIZED then
  
    -- sort by size
    local sort = {}
    for i,v in ipairs(objects.balls) do
      sort[i] = {v.shape:getRadius(), v}
    end
    table.sort(sort, function(a,b) return a[1]<b[1] end)
    local balls = {}
    for i,v in ipairs(sort) do
      balls[i] = v[2]
    end
    objects.balls = balls
  
    local balls = objects.balls
    local tag, tagx, tagy
    for i=1,#balls do
      local ball = objects.balls[i]
      local x, y = ball.body:getX(), ball.body:getY()
      local r = ball.shape:getRadius()
      
      if r > 1 then
        lg.setColor(ball.color)
        lg.circle("fill", x, y, r)
        
        lg.setLine(1, 'smooth')
        lg.setColor(0, 0, 0, 70)
        if ball == SELECTED_BALL then
          lg.setLine(3, 'smooth')
          lg.setColor(0, 0, 255, 255)
        end
        lg.circle("line", x, y, r)
      end
      
      -- hashtag label
      local label = '#'..ball.tag.name
      local width = font_smallest:getWidth(label)
      local height = font_smallest:getHeight(label)
      lg.setColor(0, 0, 0, 200)
      if r > 50 then
        lg.setColor(0, 0, 0, 200)
      elseif r > 20 then
        lg.setColor(0, 0, 0, 50)
      else
        lg.setColor(0, 0, 0, 0)
      end
      
      if ball == SELECTED_BALL then
        tag = label
        tagx = x - 0.5 * width
        tagy = y - 0.5 * height
        lg.setColor(0, 0, 0, 255)
      end
      
      if r > 1 then
        local tx, ty = x - 0.5 * width, y - 0.5 * height
        lg.setFont(font_smallest)
        lg.print(label, tx, ty)
      end
      
    end
    
    if tag then
      lg.setColor(0, 0, 0, 255)
      lg.setFont(font_smallest)
      lg.print(tag, tagx, tagy)
    end
    
    -- clock
    local time_string = get_time(objects.timer:progress())
    lg.setFont(font_large)
    lg.setColor(0, 0, 0, 255)
    lg.print(time_string, 20, 20)
    
    -- terms
    if DISPLAY_HASHTAG then
      lg.setColor(220, 240, 255, 230)
      lg.rectangle("fill", 0, 0, SCR_WIDTH, SCR_HEIGHT)
    
      hashtag = DISPLAY_HASHTAG
      local x = 0.5 * SCR_WIDTH - 0.5 * hashtag.bubble_area_width
      local y = 0.5 * SCR_HEIGHT - 0.5 * hashtag.bubble_area_height
      hashtag:draw_term_bubbles(x, y)
      
      -- draw title
      local font = font_large
      local label = '#'..hashtag.name
      local title = 'Top Terms For '
      local str = title..label
      local w = font:getWidth(str)
      local x = 0.5 * SCR_WIDTH - 0.5 * w
      local y = 20
      
      lg.setColor(0, 0, 0, 255)
      lg.setFont(font)
      lg.print(title, x, y)
      
      local x = x + font:getWidth(title)
      lg.setColor(0, 50, 200, 255)
      lg.print(label, x, y)
      
    end
    
  end

  if not DATA_INITIALIZED then
    app:draw()
    
    lg.setColor(C_ORANGE)
    lg.setFont(font_small)
    --lg.print("FPS: "..love.timer.getFPS(), 0, 0)
    
    local text = app.tweets[app.current_tweet].text
    local tstamp = app.tweets[app.current_tweet].time.time
    text = tstamp.." "..text
    lg.setFont(font_smallest)
  
    -- draw mouse pointer (for screen cast)
    lg.setColor(0, 0, 0, 255)
    lg.setLine(2)
    local x, y = love.mouse.getPosition()
    lg.line(x, y + 8, x, y, x + 5, y +8)
    
  end
  
 
  lg.setFont(font_smallest)
  lg.print(love.timer.getFPS(), 0, 0)
end















