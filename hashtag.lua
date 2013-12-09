
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- hashtag object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local hashtag = {}
hashtag.table = 'hashtag'
hashtag.id = nil
hashtag.name = nil
hashtag.x = nil
hashtag.y = nil
hashtag.width = 200
hashtag.height = 25
hashtag.bbox = nil

hashtag.clock = nil
hashtag.ttl = 60 * 15           -- time to live (in seconds)
hashtag.ttl_timer = nil
hashtag.flash_ttl = 60*15
hashtag.flash_timer = nil

hashtag.count = 0
hashtag.max_tweets = 1000
hashtag.tweet_list = nil
hashtag.hits = nil              -- list of timestamps (in seconds) in increasing
hashtag.terms = nil                             -- order. Used for graphing data.
hashtag.num_terms = 0
             
hashtag.rate = 0                    -- in tweets per minute
hashtag.max_rate = 0                -- top rate achieved in hashtag lifetime
hashtag.rate_update_min_count = 20
hashtag.rate_interval = 60 * 10      -- interval over which rate is calculated
hashtag.rate_update_time = 0.5        -- how often to update rate
hashtag.rate_update_timer = nil

hashtag.sort_score = 0

hashtag.document_terms = nil
hashtag.doc_term_count = 0
                                
hashtag.mouse_hover = false

hashtag.bubble_area_width = 1200
hashtag.bubble_area_height = 800

local hashtag_mt = { __index = hashtag }
function hashtag:new(app, name, flash_curve)
  local clock = app.clock
  local real_clock = app.real_clock

  local ttl_timer = timer:new(clock, hashtag.ttl)
  ttl_timer:start()
  
  local rate_timer = timer:new(real_clock, hashtag.rate_update_time)
  rate_timer:start()
  
  local tweets = {}
  local hits = {}
  
  local lower_name = string.lower(name)
  
  local bbox = bbox:new(0, 0, 0, 0)
  
  local flash_timer = timer:new(master_timer, hashtag.flash_ttl)
  
  return setmetatable({app = app,
                       clock = clock,
                       real_clock = real_clock,
                       ttl_timer = ttl_timer,
                       tweet_list = tweets,
                       terms = {},
                       name = name,
                       hits = hits,
                       id = lower_name,
                       bbox = bbox,
                       rate_update_timer = rate_timer,
                       flash_timer = flash_timer,
                       flash_curve = flash_curve,
                       document_terms = {},
                       doc_term_count = 0}, hashtag_mt)
end

function hashtag:init_document(all_terms)
  local document_terms = {}
  local my_terms = self.terms
  local doc_term_count = 0
  local max_term_count = 0
  local max_term = ''
  for term,count in pairs(all_terms) do
    if my_terms[term] then
      document_terms[term] = my_terms[term]
      doc_term_count = doc_term_count + 1
      
      if my_terms[term] > max_term_count then
        max_term_count = my_terms[term]
        max_term = term
      end
    end
  end
  
  -- find term frequencies
  local tf = {}
  for term,count in pairs(document_terms) do
    tf[term] = count / max_term_count
  end
  
  
  self.document_terms = document_terms
  self.doc_term_count = doc_term_count
  self.max_term_count = max_term_count
  self.max_term = max_term
  self.term_frequencies = tf
  
end

function hashtag:init_tfidf(idf)
  local tf = self.term_frequencies
  local tfidf = {}
  
  for term,freq in pairs(tf) do
    tfidf[#tfidf + 1] = {freq * idf[term], term}
  end
  table.sort(tfidf, function(a,b) return a[1]>b[1] end)
  
  local top_terms = {}
  local max_terms = 25
  for i=1,max_terms do
    if not tfidf[i] then
      break
    end
    top_terms[i] = tfidf[i][2]
  end
  
  --[[
  print()
  print('TOP TERMS for '..self.name)
  for i=1,25 do
    if top_terms[i] == nil then
      break
    end
    print(top_terms[i])
  end
  print()
  ]]--
  
  -- display graphics
  local term_bubbles = {}
  local max_weight = tfidf[1][1]
  local min_weight = tfidf[#tfidf][1]
  for i=1,#top_terms do
    local term = top_terms[i]
    local weight = tfidf[i][1]
    
    local ratio = weight / max_weight
    local min_size = 30
    local max_size = 150
    local radius = 50 + ratio * (max_size - min_size)
    
    local width, height = self.bubble_area_width, self.bubble_area_height
    local found_position = false
    local x, y
    local pos
    local try_count = 0
    local max_try_count = 20
    
    while not found_position do
      x = math.random(radius, width - radius)
      y = math.random(radius, height - radius)
      pos = vector2:new(x, y)
      local ok = true
      
      for i=1,#term_bubbles do
        local r1, p1 = radius, pos
        local r2, p2 = term_bubbles[i].radius, term_bubbles[i].pos
        local dist = vector2:dist(p1, p2)
        if dist < r1 + r2 then
          ok = false
          break
        end
      end
      
      if ok then
        found_position = true
      end
      
      try_count = try_count + 1
      if try_count > max_try_count then
        break
      end
    
    end
    
    if found_position then
      local bubble = {}
      bubble.term = term
      bubble.radius = radius
      bubble.pos = pos
      bubble.x = x
      bubble.y = y
      bubble.color = {255, 0, 0, 255}
      
      term_bubbles[#term_bubbles + 1] = bubble
    end
    
  end
  
  self.top_terms = top_terms
  self.term_bubbles = term_bubbles
end

function hashtag:is_expired()
  if self.ttl_timer:progress() == 1 then
    return true
  end
  
  return false
end

function hashtag:check_mouse(mx, my)
  if self.bbox:contains_point(vector2:new(mx, my)) then
    self.mouse_hover = true
    return true
  else
    self.mouse_hover = false
    return false
  end
end

function hashtag:add_tweet(tweet)
  local tweets = self.tweet_list
  table.insert(tweets, 1, tweet)
  if #tweets > self.max_tweets then
    table.remove(tweets, #tweets)
  end
  
  self.count = self.count + 1
  self.ttl_timer:start()
  
  local seconds = tweet.time.seconds
  self.hits[#self.hits + 1] = seconds
  
  --self.flash_timer:start()
end

function hashtag:add_term(term)
  if self.terms[term] then
    self.terms[term] = self.terms[term] + 1
  else
    self.terms[term] = 1
    self.num_terms = self.num_terms + 1
  end
end

-- score between 0 and 1
function hashtag:set_score(score)
  self.sort_score = score
end

------------------------------------------------------------------------------
function hashtag:update(dt)
  if self.count >= hashtag.rate_update_min_count and 
     self.rate_update_timer:progress() == 1 and not app.data_finished then
    self:_update_rate()
    self.rate_update_timer:start()
  end
end

function hashtag:_update_rate()
  local interval = self.rate_interval
  local hits = self.hits
  local count = 0
  local start_time = hits[#hits] - interval
  for i=#hits,1,-1 do
    local t = hits[i]
    if t > start_time then
      count = count + 1
    else
      break
    end
  end
  
  self.rate = (count / interval) * 60
  if self.rate > self.max_rate then
    self.max_rate = self.rate
  end
  
  return self.rate
end

------------------------------------------------------------------------------
function hashtag:draw(x, y)
  x = x or self.x
  y = y or self.y

  -- score background
  lg.setColor(C_DARKER_GREY)
  lg.rectangle('fill', x, y, self.width * self.sort_score, self.height)
  
  
  -- text
  lg.setFont(font_smallest)
  lg.setColor(C_ORANGE)
  if self.mouse_hover or self.selected then
    lg.setColor(C_RED)
  end
  lg.print('#'..self.name, x + 5, y + 5)
  
  lg.setColor(C_DARKER_GREY)
  if self.mouse_hover or self.selected then
    lg.setColor(C_GREEN)
  end
  
  -- outline
  lg.rectangle('line', x, y, self.width, self.height)
  --lg.setColor(26, 224, 14, self.flash_curve:get((1-self.flash_timer:progress())) * 255)
  --lg.rectangle('line', x, y, self.width, self.height)
  
end

function hashtag:draw_term_bubbles(x, y)
  local bubbles = self.term_bubbles
  
  local max = 0
  local min = 1000
  for i=1,#bubbles do
    if bubbles[i].radius > max then
      max = bubbles[i].radius
    end
    if bubbles[i].radius < min then
      min = bubbles[i].radius
    end
  end
  
  local g = GRADIENT
  lg.setLine(3, "smooth")
  for i=1,#bubbles do
    local bubble = bubbles[i]
    local x, y = x + bubble.x, y + bubble.y
    local r = bubble.radius
    local term = bubble.term
    
    local idx = math.floor(((r - min) / (max-min)) * #g)
    if idx == 0 then idx = 1 end
    local color = g[idx]
    
    lg.setFont(font_smallest)
    lg.setColor(255, 255, 255, 255)
    local w = font_smallest:getWidth(term)
    local h = font_smallest:getWidth(term)
    local text_x, text_y = x - 0.5 * w, y
    
    lg.setColor(color)
    lg.circle('fill', x, y, r)
    lg.setColor(0, 0, 0, 255)
    lg.circle('line', x, y, r)
    
    lg.setColor(255, 255, 255, 255)
    lg.print(term, text_x, text_y)
  end
end

function hashtag:set_position(x, y)
  local bbox = self.bbox
  bbox.x = x
  bbox.y = y
  bbox.width = self.width
  bbox.height = self.height
  
  self.x = x
  self.y = y
end

return hashtag









