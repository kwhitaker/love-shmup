local C = require('constants')
local bounds = require('game.bounds')
local new_player = require('entities.player')

local function update_all(list, dt, stage)
  for _, e in ipairs(list) do
    e:update(dt, stage)
  end
end

local function draw_all(list)
  for _, e in ipairs(list) do
    e:draw()
  end
end

return function()
  local stage = {
    player = new_player(C.VIEW_W / 2, C.VIEW_H - 80),
    player_bullets = {}
  }

  function stage:update(dt)
    self.player:update(dt, self)
    update_all(self.player_bullets, dt, self)
    bounds.sweep(self.player_bullets)
  end

  function stage:draw()
    draw_all(self.player_bullets)
    self.player:draw()
  end

  return stage
end
