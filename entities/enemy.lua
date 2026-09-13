local new_bullet = require('entities.bullet')

local RADIUS = 14
local BULLET_SPEED = 220
local BULLET_COLOR = { 1, 0.5, 0.3 }

-- movement patterns: given the enemy and how long it has been alive,
-- return a velocity. swap these out per wave later
local patterns = {
  straight = function(e, age)
    return 0, 120
  end,
  weave = function(e, age)
    return math.sin(age * 3) * 160, 100
  end,
  zigzag = function(e, age)
    local speed = 160
    local period = 2.0

    local t = (age % period) / period
    local x = 1 - 4 * math.abs(t - 0.5)

    return x * speed, 100
  end
}

return function(x, y, pattern_name)
  local enemy = {
    x = x,
    y = y,
    r = RADIUS,
    health = 1,
    dead = false,
    age = 0,
    pattern = patterns[pattern_name or 'straight'],
    fire_interval = 1.4,
    cooldown = 0.6,
  }

  function enemy:update(dt, stage)
    self.age = self.age + dt
    local vx, vy = self.pattern(self, self.age)
    self.x = self.x + vx * dt
    self.y = self.y + vy * dt

    self.cooldown = self.cooldown - dt
    if self.cooldown <= 0 then
      self.cooldown = self.fire_interval
      -- aim at the player: direction vector, normalized, times speed
      local p = stage.player
      local dx, dy = p.x - self.x, p.y - self.y
      local len = math.sqrt(dx * dx + dy * dy)
      if len > 0 then
        local b = new_bullet(self.x, self.y, dx / len * BULLET_SPEED, dy / len * BULLET_SPEED, BULLET_COLOR)
        table.insert(stage.enemy_bullets, b)
      end
    end
  end

  function enemy:hit(damage)
    self.health = self.health - damage
    if self.health <= 0 then
      self.dead = true
    end
  end

  function enemy:draw()
    love.graphics.setColor(1, 0.4, 0.4)
    love.graphics.rectangle('fill', self.x - self.r, self.y - self.r, self.r * 2, self.r * 2)
    love.graphics.setColor(1, 1, 1)
  end

  return enemy
end
