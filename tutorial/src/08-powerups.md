# Power-ups

The last entity, and the one with the oddest behavior spec: bounce around the screen for a while, then stop caring about the edges and drift off. It's a good test of whether the structure holds up, since this is the only thing that's only sometimes bounded.

## The power-up

`entities/powerup.lua`:

```lua
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
```

**Random direction.** Pick an angle, take its cosine and sine, scale by speed. That's a unit vector in a random direction, the enemy's normalize trick run backwards.

**Bouncing.** The clamp from the player, plus flipping the velocity component that crossed the edge. Note we also set the position to the edge, not just flip the velocity. Otherwise a fast-moving thing can end up two pixels past the edge, flip, still be past the edge next frame, flip again, and sit there vibrating. Snap, then reflect.

**The `bounded` flag.** That whole block is inside `if self.bounded`. When `ttl` runs out the flag goes false, the velocity keeps doing what it was doing, and within a second or two the thing is past the margin and the chapter 4 sweep removes it, unchanged. The "flies off screen and vanishes" behavior is the *absence* of code, which is the nicest kind.

**`apply`.** The power-up knows what it does to a player. Multiply the fire interval by 0.8, floor it at 0.05 so it can't hit zero. Zero interval means infinite bullets per frame; you'd find out quickly.

## The spawner

`game/spawner.lua`:

```lua
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
```

A second timer, longer, spawning somewhere in the top half of the screen.

## The stage

`game/stage.lua`:

```lua
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
```

One more list, one more update, one more sweep, one more draw, and one more collision pair. Power-ups aren't in any pair with enemies or bullets, so an enemy flying through one does nothing. Exactly the spec, zero code.

## Checkpoint

Run it. A yellow diamond appears a few seconds in and ricochets around. Grab it: the HUD's fire rate number drops and the bullet stream thickens. Leave one alone for eight seconds and watch it stop bouncing and leave.

That's the MVP. Everything on the list from the introduction is in.

## Exercises

- Make the power-up drop from a dead enemy instead of on a timer — say a 1-in-4 chance. Where does that code go: the enemy, the stage, or the spawner? Try to argue for each.
- Add a second power-up type: extra life. The color, the `apply`, and nothing else should change.
- The power-up bounces with its `r`, but the player clamps with `DRAW_SIZE`. Which is right for each? Why are they different?
