local C = require('constants')
local bounds = require('game.bounds')
local collision = require('game.collision')
local new_player = require('entities.player')
local new_spawner = require('game.spawner')

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
    player_bullets = {},
    enemies = {},
    enemy_bullets = {},
    powerups = {},
    spawner = new_spawner(),
    score = 0,
  }

  function stage:update(dt)
    self.spawner:update(dt, self)

    self.player:update(dt, self)
    update_all(self.player_bullets, dt, self)
    update_all(self.enemies, dt, self)
    update_all(self.enemy_bullets, dt, self)
    update_all(self.powerups, dt, self)

    self:resolve_collisions()

    bounds.sweep(self.player_bullets)
    bounds.sweep(self.enemies)
    bounds.sweep(self.enemy_bullets)
    bounds.sweep(self.powerups)
  end

  function stage:resolve_collisions()
    collision.each_pair(self.player_bullets, self.enemies, function(bullet, enemy)
      bullet.dead = true
      enemy:hit(1)
      if enemy.dead then
        self.score = self.score + 100
      end
    end)

    collision.each_against(self.player, self.enemy_bullets, function(player, bullet)
      bullet.dead = true
      player:hit(1)
    end)

    collision.each_against(self.player, self.enemies, function(player, enemy)
      enemy.dead = true
      player:hit(1)
    end)

    collision.each_against(self.player, self.powerups, function(player, powerup)
      powerup.dead = true
      powerup:apply(player)
    end)
  end

  function stage:is_over()
    return self.player.dead
  end

  function stage:draw_hud()
    local p = self.player
    love.graphics.print(('lives %d   health %d   fire rate %.2f'):format(p.lives, p.health, p.fire_interval), 10, 10)
    love.graphics.printf(('score %d'):format(self.score), 0, 10, C.VIEW_W - 10, 'right')
  end

  function stage:draw()
    draw_all(self.enemy_bullets)
    draw_all(self.player_bullets)
    draw_all(self.enemies)
    draw_all(self.powerups)
    self.player:draw()
    self:draw_hud()
  end

  return stage
end
