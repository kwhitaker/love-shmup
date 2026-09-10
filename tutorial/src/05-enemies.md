# Enemies and the spawner

Something to shoot at. Something that shoots back.

## The enemy

`entities/enemy.lua`:

```lua
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

  function enemy:draw()
    love.graphics.setColor(1, 0.4, 0.4)
    love.graphics.rectangle('fill', self.x - self.r, self.y - self.r, self.r * 2, self.r * 2)
    love.graphics.setColor(1, 1, 1)
  end

  return enemy
end
```

**Patterns.** Movement is a function that takes the enemy and its age and returns a velocity. `straight` ignores both. `weave` uses the age to drive a sine on x, so the enemy snakes down the screen. This is the smallest version of a real shmup idea: an enemy's behavior is data you hand it at spawn time, not something baked into the entity. Adding a pattern is adding a function to the table.

**Aiming.** The enemy gets the stage on update, same as the player, and reads the player's position off it. Subtract to get a direction vector, divide by its length to normalize, multiply by speed. The `len > 0` guard is for the frame an enemy spawns exactly on top of the player. It happens, and dividing by zero gives you a bullet at `nan, nan` that never dies.

**`cooldown` starts at 0.6, not 0.** An enemy that fires the instant it appears, from offscreen, is unfair and looks like a bug.

## The spawner

`game/spawner.lua`:

```lua
local C = require('constants')
local new_enemy = require('entities.enemy')

local ENEMY_INTERVAL = 1.1
local PATTERNS = { 'straight', 'weave', 'weave' }

return function()
  local spawner = {
    enemy_timer = 0.5,
  }

  function spawner:update(dt, stage)
    self.enemy_timer = self.enemy_timer - dt
    if self.enemy_timer <= 0 then
      self.enemy_timer = ENEMY_INTERVAL
      local x = love.math.random(40, C.VIEW_W - 40)
      local pattern = PATTERNS[love.math.random(#PATTERNS)]
      table.insert(stage.enemies, new_enemy(x, -20, pattern))
    end
  end

  return spawner
end
```

Same countdown-timer pattern as firing. Enemies appear just above the top edge, inside the offscreen margin, so the sweep doesn't kill them on their first frame. `-20` is fine because the margin is 40. Spawn at `-60` and nothing ever shows up, and you'll spend a confused ten minutes on it.

`love.math.random` instead of `math.random`: LÖVE seeds its own generator, and it's the one that'll matter later if you want seeded, replayable runs. `PATTERNS` lists `weave` twice so it comes up two-thirds of the time. Cheap weighting.

## The stage

`game/stage.lua`:

```lua
local C = require('constants')
local bounds = require('game.bounds')
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
    spawner = new_spawner(),
  }

  function stage:update(dt)
    self.spawner:update(dt, self)

    self.player:update(dt, self)
    update_all(self.player_bullets, dt, self)
    update_all(self.enemies, dt, self)
    update_all(self.enemy_bullets, dt, self)

    bounds.sweep(self.player_bullets)
    bounds.sweep(self.enemies)
    bounds.sweep(self.enemy_bullets)
  end

  function stage:draw()
    draw_all(self.enemy_bullets)
    draw_all(self.player_bullets)
    draw_all(self.enemies)
    self.player:draw()
  end

  return stage
end
```

Two new lists and a spawner. The update order is starting to matter, so here it is spelled out:

1. Spawner runs first, so a freshly spawned enemy gets its first update this frame
2. Player, then bullets, then enemies, then enemy bullets
3. Sweep every list

Next chapter slots collision between 2 and 3.

## Checkpoint

Run it. Red squares drift down and shoot orange bullets at you. Nothing collides yet, so it's a light show. Dodge anyway.

## Exercises

- Add a `zigzag` pattern: move right for a second, then left for a second, always drifting down. (`age % 2 < 1` is a useful expression.)
- Make the spawner speed up: every enemy spawned shaves a little off `ENEMY_INTERVAL`, down to some floor.
