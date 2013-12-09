
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- twitter_feed object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local twitter_feed = {}
local feed = twitter_feed
feed.x = nil
feed.y = nil
feed.width = nil
feed.height = nil
feed.bbox = nil
feed.display_curve = nil

-- tweet.data
feed.tweets = nil
feed.original_tweets = nil
feed.font = nil
feed.font_height = nil
feed.max_lines = nil
feed.time_stamp_width = nil
feed.text_x = nil
feed.line_pad = 3
feed.text_display = nil
feed.timestamp_display = nil

feed.display_timer = nil
feed.display_time = 0.8


local twitter_feed_mt = { __index = twitter_feed }
function twitter_feed:new(app, x, y, width, height, tweets, font, display_curve)
  local bbox = bbox:new(x, y, width, height)

  local font_height = font:getHeight("A")
  local num_lines = math.floor(height / (font_height + twitter_feed.line_pad))
  
  local time_stamp_width = font:getWidth("[13-Oct-2013]")
  local text_x = x + time_stamp_width
  
  local display_timer = timer:new(app.real_clock, twitter_feed.display_time)
  display_timer:start()
  
  return setmetatable({ x = x,
                        y = y,
                        width = width,
                        height = height,
                        bbox = bbox,
                        tweets = tweets,
                        original_tweets = tweets,
                        clock = app.real_clock,
                        font = font,
                        font_height = font_height,
                        max_lines = num_lines,
                        text_x = text_x,
                        time_stamp_width = time_stamp_width,
                        display_curve = display_curve,
                        display_timer = display_timer}, twitter_feed_mt)
end

function twitter_feed:set_tweet_data(tweets)
  self.tweets = tweets
  self.display_timer:start()
end

function twitter_feed:reset_tweet_data()
  self.tweets = self.original_tweets
  self.display_timer:start()
end

------------------------------------------------------------------------------
function twitter_feed:update(dt)
  local tweets = self.tweets
  
  local text_list = {}
  local timestamp_list = {}
  
  for i=1,math.min(#tweets, self.max_lines) do
    local tweet = tweets[i]
    local text = tweet.text
    local tstamp = "["..tweet.time.time.."]"
    
    timestamp_list[i] = tstamp
    text_list[i] = text
  end
  
  self.text_display = text_list
  self.timestamp_display = timestamp_list
  
end

------------------------------------------------------------------------------
function twitter_feed:draw()
  lg.setColor(C_DARKER_GREY)
  lg.rectangle("line", self.x, self.y, self.width, self.height)
  
  -- draw text
  local x, y = self.text_x, self.y + self.height - self.font_height
  local ystep = self.font_height + self.line_pad
  local curve = self.display_curve
  local timer = self.display_timer
  local text_list = self.text_display
  local timestamps = self.timestamp_display
  local fade_num = 5
  
  lg.setFont(self.font)
  for i=1,#text_list do
    lg.setColor(0, 0, 0, curve:get(timer:progress()) * 255)
    lg.print(text_list[i], x, y - (i - 1) * ystep)
  end
  
  lg.setFont(self.font)
  local x, y = self.x, self.y + self.height - self.font_height
  for i=1,#timestamps do
    lg.setColor(0, 101, 255, curve:get(timer:progress()) * 255)
    lg.print(timestamps[i], x, y - (i - 1) * ystep)
  end
  
  
  
end

return twitter_feed















