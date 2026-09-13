local C = require('constants')
local new_enemy = require('entities.enemy')
local new_powerup = require('entities.powerup')

local ENEMY_INTERVAL = 1.1
local POWERUP_INTERVAL = 7
local PATTERNS = { 'straight', 'weave', 'weave' }

return function()
  local spawner = {
    enemy_timer = 0.5,
    powerup_timer = 3,
  }

  function spawner:update(dt, stage)
    self.enemy_timer = self.enemy_timer - dt
    if self.enemy_timer <= 0 then
      self.enemy_timer = ENEMY_INTERVAL
      local x = love.math.random(40, C.VIEW_W - 40)
      local pattern = PATTERNS[love.math.random(#PATTERNS)]
      table.insert(stage.enemies, new_enemy(x, -20, pattern))
    end

    self.powerup_timer = self.powerup_timer - dt
    if self.powerup_timer <= 0 then
      self.powerup_timer = POWERUP_INTERVAL
      local x = love.math.random(40, C.VIEW_W - 40)
      local y = love.math.random(40, C.VIEW_H / 2)
      table.insert(stage.powerups, new_powerup(x, y))
    end
  end

  return spawner
end
