return function(x, y, vx, vy, color)
  local bullet = {
    x = x,
    y = y,
    vx = vx,
    vy = vy,
    r = 4,
    color = color,
    dead = false,
  }

  function bullet:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
  end

  function bullet:draw()
    love.graphics.setColor(self.color)
    love.graphics.circle('fill', self.x, self.y, self.r)
    love.graphics.setColor(1, 1, 1)
  end

  return bullet
end
