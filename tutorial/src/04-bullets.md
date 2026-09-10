# Bullets

Constant fire, on a timer. Then the boring but important part: getting rid of bullets once they leave the screen.

## The bullet

`entities/bullet.lua`:

```lua
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
```

One factory for both sides. A bullet doesn't know whether it's friendly. The list it lives in decides that, which is the next chapter's trick. It just has a velocity and a color.

## Firing

The player gets two new fields, `fire_interval` and `cooldown`, and its `update` now takes a second argument: the stage. That's how an entity spawns things: it's handed the stage and appends to a list. Full file, since a few lines moved:

`entities/player.lua`:

```lua
local C = require('constants')

local new_bullet = require('entities.bullet')

local SPEED = 320
local RADIUS = 6      -- hitbox, deliberately tiny
local DRAW_SIZE = 16  -- what you actually see
local BULLET_SPEED = 600
local BULLET_COLOR = { 0.4, 0.9, 1 }

return function(x, y)
  local player = {
    x = x,
    y = y,
    r = RADIUS,
    dead = false,
    fire_interval = 0.2,
    cooldown = 0,
  }

  function player:update(dt, stage)
    local dx, dy = 0, 0
    if love.keyboard.isDown('left', 'a') then dx = dx - 1 end
    if love.keyboard.isDown('right', 'd') then dx = dx + 1 end
    if love.keyboard.isDown('up', 'w') then dy = dy - 1 end
    if love.keyboard.isDown('down', 's') then dy = dy + 1 end

    -- normalize diagonals so they aren't faster than straight lines
    if dx ~= 0 and dy ~= 0 then
      dx, dy = dx * 0.7071, dy * 0.7071
    end

    self.x = self.x + dx * SPEED * dt
    self.y = self.y + dy * SPEED * dt

    -- clamp to the viewport, inset by the drawn size so the ship never clips
    self.x = math.max(DRAW_SIZE, math.min(C.VIEW_W - DRAW_SIZE, self.x))
    self.y = math.max(DRAW_SIZE, math.min(C.VIEW_H - DRAW_SIZE, self.y))

    self.cooldown = self.cooldown - dt
    if self.cooldown <= 0 then
      self.cooldown = self.fire_interval
      local b = new_bullet(self.x, self.y - DRAW_SIZE, 0, -BULLET_SPEED, BULLET_COLOR)
      table.insert(stage.player_bullets, b)
    end
  end

  function player:draw()
    love.graphics.setColor(0.4, 0.9, 1)
    love.graphics.polygon('fill',
      self.x, self.y - DRAW_SIZE,
      self.x - DRAW_SIZE * 0.7, self.y + DRAW_SIZE * 0.7,
      self.x + DRAW_SIZE * 0.7, self.y + DRAW_SIZE * 0.7)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle('line', self.x, self.y, self.r)
  end

  return player
end
```

The timer pattern is the one you'll use for everything from here on: a number, subtract `dt` every frame, when it crosses zero do the thing and reset it. No timer library. `cooldown` starts at zero so the first shot is immediate.

## Cleaning up

Bullets fly off the top at 600 pixels a second, five a second. In a minute that's three hundred tables that will never be drawn again, still being updated. We need to throw them away, and we'll need the same thing for enemies, enemy bullets, and power-ups, so it goes in its own module.

`game/bounds.lua`:

```lua
local C = require('constants')

local bounds = {}

-- true once an entity is far enough outside the viewport that nobody will miss it
function bounds.is_offscreen(e)
  local m = C.OFFSCREEN_MARGIN
  return e.x < -m or e.x > C.VIEW_W + m or e.y < -m or e.y > C.VIEW_H + m
end

-- remove dead and offscreen entities in place. walk backwards so removing
-- an element doesn't shift the ones we haven't looked at yet
function bounds.sweep(list)
  for i = #list, 1, -1 do
    local e = list[i]
    if e.dead or bounds.is_offscreen(e) then
      list[i] = list[#list]
      list[#list] = nil
    end
  end
end

return bounds
```

Two things here are load-bearing.

**Walk backwards.** Breakout removed entities in a forward `while` loop with `table.remove`, which shifts every later element down by one. Removing during a forward `ipairs` is worse — you skip the element that slid into the hole. Iterating from `#list` down to 1 means anything you remove is behind you.

**Swap with the last, then drop the last.** `table.remove(list, i)` is O(n): it shifts everything after `i`. Copying the last element into slot `i` and nil-ing the end is O(1). The list's order changes, but nothing here cares about order. This is the standard removal for game entity lists, and it's why the backwards walk matters: the element swapped into `i` was already checked.

The `dead` flag isn't used by anything yet. It will be: collision marks things dead, and the sweep at the end of the frame removes them. Nothing removes itself mid-update.

## The stage

`game/stage.lua`:

```lua
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
    player_bullets = {},
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
```

`update_all` and `draw_all` are file-local helpers — every list is going to need them. Draw order is bottom-up, bullets first so the ship draws over them.

## Checkpoint

Run it. Constant stream of bullets. To convince yourself the sweep works, print `#self.player_bullets` in `stage:update` — it should climb to about five and stay there.

## Exercises

- Change `fire_interval` to `0.05`. Does the count stabilize? At what?
- Make the ship fire two bullets, one from each wingtip.
