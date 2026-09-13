local C = require('constants')

local RADIUS = 10
local SPEED = 150
local LIFETIME = 8
local FIRE_RATE_MULT = 0.8
local MIN_FIRE_INTERVAL = 0.05

return function(x, y)
  local angle = love.math.random() * math.pi * 2
  local powerup = {
    x = x,
    y = y,
    r = RADIUS,
    vx = math.cos(angle) * SPEED,
    vy = math.sin(angle) * SPEED,
    dead = false,
    ttl = LIFETIME,
    bounded = true,
  }

  function powerup:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    self.ttl = self.ttl - dt
    if self.ttl <= 0 then
      self.bounded = false
    end

    -- while bounded, reflect off the viewport edges. once the timer runs out
    -- the same velocity carries it offscreen and the sweep takes it
    if self.bounded then
      if self.x < self.r then
        self.x, self.vx = self.r, -self.vx
      elseif self.x > C.VIEW_W - self.r then
        self.x, self.vx = C.VIEW_W - self.r, -self.vx
      end
      if self.y < self.r then
        self.y, self.vy = self.r, -self.vy
      elseif self.y > C.VIEW_H - self.r then
        self.y, self.vy = C.VIEW_H - self.r, -self.vy
      end
    end
  end

  function powerup:apply(player)
    player.fire_interval = math.max(MIN_FIRE_INTERVAL, player.fire_interval * FIRE_RATE_MULT)
  end

  function powerup:draw()
    love.graphics.setColor(1, 0.9, 0.2)
    love.graphics.polygon('fill',
      self.x, self.y - self.r,
      self.x + self.r, self.y,
      self.x, self.y + self.r,
      self.x - self.r, self.y)
    love.graphics.setColor(1, 1, 1)
  end

  return powerup
end
