# Collisions

Everything is a circle. That decision was made back in chapter 3 when the player got an `r`, and it's why this chapter is short.

## Circle overlap

`game/collision.lua`:

```lua
local collision = {}

-- circle vs circle. compare squared distances so we never need a sqrt
function collision.overlaps(a, b)
  local dx, dy = a.x - b.x, a.y - b.y
  local reach = a.r + b.r
  return dx * dx + dy * dy < reach * reach
end

-- every live pair between two lists. on_hit decides what happens
function collision.each_pair(list_a, list_b, on_hit)
  for _, a in ipairs(list_a) do
    if not a.dead then
      for _, b in ipairs(list_b) do
        if not b.dead and collision.overlaps(a, b) then
          on_hit(a, b)
        end
      end
    end
  end
end

-- one entity against a list
function collision.each_against(one, list, on_hit)
  if one.dead then return end
  for _, b in ipairs(list) do
    if not b.dead and collision.overlaps(one, b) then
      on_hit(one, b)
    end
  end
end

return collision
```

Two circles overlap when the distance between their centers is less than the sum of their radii. Distance needs a square root, and square roots are slow enough that you don't want a few thousand per frame. So compare *squared* distance to *squared* reach instead — same answer, no `sqrt`. You'll see this everywhere.

The two loop helpers are the other half. `each_pair` walks every combination of two lists; `each_against` is the same thing for one entity against a list, so we don't have to wrap the player in a one-element table. Both skip anything already flagged `dead`, which matters when a single bullet overlaps two enemies in one frame — it should only hit one.

## Which pairs

This is what lists-per-kind buys you. If everything lived in one flat list, you'd need each entity to carry a layer and a mask (a bitmask saying "I am an enemy bullet, I collide with players") and check it per pair. That's what Box2D's collision filters are, and it's what learn2love's bitmask chapter is building toward. It's the right tool when you have a dozen kinds of thing.

We have five. So we just write down the pairs we care about:

- player bullets × enemies
- player × enemy bullets
- player × enemies

That's it. Power-ups (next chapter) add one more. Anything not in the list (enemy bullets against enemies, player bullets against each other) is never checked. No filtering, because nothing needs to be filtered out.

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
    spawner = new_spawner(),
  }

  function stage:update(dt)
    self.spawner:update(dt, self)

    self.player:update(dt, self)
    update_all(self.player_bullets, dt, self)
    update_all(self.enemies, dt, self)
    update_all(self.enemy_bullets, dt, self)

    self:resolve_collisions()

    bounds.sweep(self.player_bullets)
    bounds.sweep(self.enemies)
    bounds.sweep(self.enemy_bullets)
  end

  function stage:resolve_collisions()
    collision.each_pair(self.player_bullets, self.enemies, function(bullet, enemy)
      bullet.dead = true
      enemy:hit(1)
    end)

    collision.each_against(self.player, self.enemy_bullets, function(player, bullet)
      bullet.dead = true
      print('player hit by bullet')
    end)

    collision.each_against(self.player, self.enemies, function(player, enemy)
      enemy.dead = true
      print('player rammed an enemy')
    end)
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

`resolve_collisions` runs after every update and before the sweep. Each callback does two things: flag what dies, and apply damage. The bullet sets `dead` directly. The enemy gets a `hit` method, because "loses health, dies at zero" is going to be the same logic for the player and it's worth having it in one place per entity.

The player's two callbacks just print for now. Next chapter replaces those with the real thing.

## The enemy learns to take a hit

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
```

One new method. `health` was already there; now it goes down.

## Checkpoint

Run it. Enemies die when shot. Get hit and the console says so. Ram an enemy and it vanishes.

Watch for the swept-on-the-same-frame case: a bullet kills an enemy, both get flagged, and the sweep at the end of `update` removes both. Neither is ever drawn in a dead state, because draw happens after update. Mark-then-sweep, doing its job.

## Exercises

- Give enemies 3 health and make them flash white for a frame when hit. (A `flash` timer, same as every other timer.)
- Print how many overlap checks happen per frame. With ten enemies and thirty bullets, what's the number? When would it get scary?
