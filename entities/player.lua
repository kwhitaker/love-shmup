local C = require('constants')
local new_bullet = require('entities.bullet')

local SPEED = 320
local RADIUS = 6     -- hitbox
local DRAW_SIZE = 16 -- bigger than hitbox on purpose
local DIAG_NORM = 0.7071
local BULLET_SPEED = 600
local BULLET_COLOR = { 0.4, 0.9, 1 }

return function(x, y)
  local player = {
    x = x,
    y = y,
    r = RADIUS,
    dead = false,
    fire_interval = 0.2,
    cooldown = 0
  }

  function player:update(dt, stage)
    local dx, dy = 0, 0
    local spd = SPEED

    if love.keyboard.isDown('left', 'a') then dx = dx - 1 end
    if love.keyboard.isDown('right', 'd') then dx = dx + 1 end
    if love.keyboard.isDown('up', 'w') then dy = dy - 1 end
    if love.keyboard.isDown('down', 's') then dy = dy + 1 end

    -- slow down for "focus" mode. Makes dodging easier
    if love.keyboard.isDown('lshift') then spd = SPEED / 2 end

    -- normalize diagonals so they aren't faster than straight lines
    if dx ~= 0 and dy ~= 0 then
      dx, dy = dx * DIAG_NORM, dy * DIAG_NORM
    end

    self.x = self.x + dx * spd * dt
    self.y = self.y + dy * spd * dt

    -- clamp to viewport. inset by DRAW_SIZE so ship does not clip
    self.x = math.max(DRAW_SIZE, math.min(C.VIEW_W - DRAW_SIZE, self.x))
    self.y = math.max(DRAW_SIZE, math.min(C.VIEW_H - DRAW_SIZE, self.y))

    -- bullet fire cooldown
    self.cooldown = self.cooldown - dt
    if self.cooldown <= 0 then
      self.cooldown = self.fire_interval
      local b = new_bullet(self.x, self.y - DRAW_SIZE, 0, -BULLET_SPEED, BULLET_COLOR)
      table.insert(stage.player_bullets, b)
    end
  end

  function player:draw()
    love.graphics.setColor(0.4, 0.9, 1)
    love.graphics.polygon('fill', self.x, self.y - DRAW_SIZE, self.x - DRAW_SIZE * 0.7, self.y + DRAW_SIZE * 0.7,
      self.x + DRAW_SIZE * 0.7, self.y + DRAW_SIZE * 0.7)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle('line', self.x, self.y, self.r)
  end

  return player
end
