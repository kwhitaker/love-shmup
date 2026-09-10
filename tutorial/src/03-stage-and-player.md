# The stage and the player

Now the actual game. Two new pieces: a *stage* that owns everything alive in the current round, and the player.

## Why a stage

The `play` state could just hold the player and the enemy list directly. Splitting it out is about ownership. `play` is a scene: it sits on the gamestate stack and routes callbacks. The stage is the round: the player, the lists, the score, the rules. When `play:enter` runs, it makes a fresh stage; when the round is over, `play` reads the score off it and switches away. Keeping the two apart means restart is just "new stage."

A note on naming: breakout called its Box2D world `world`. That word is taken in LÖVE-speak, and the moment you add a camera you'll want it for something else. `stage` it is.

## The player

`entities/player.lua`:

```lua
local C = require('constants')

local SPEED = 320
local RADIUS = 6      -- hitbox, deliberately tiny
local DRAW_SIZE = 16  -- what you actually see

return function(x, y)
  local player = {
    x = x,
    y = y,
    r = RADIUS,
    dead = false,
  }

  function player:update(dt)
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

Things worth stopping on:

**It's a factory, not a class.** Same shape as breakout's entities: a function that builds a table, hangs methods on it, returns it. There are class libraries for Lua (`classic`, `middleclass`) and you may want one eventually. For now the closure is plenty.

**Movement is arithmetic.** No body, no velocity setter. Read the keys, build a direction, multiply by speed and `dt`, add to position. `love.keyboard.isDown` takes several keys and returns true if any is held, which is why arrows and WASD both work in one call.

**The diagonal fix.** Holding up and right gives a direction of `(1, -1)`, which has length √2 — you'd move 41% faster diagonally. Multiplying both by `0.7071` (that's 1/√2) brings it back to length 1. Every top-down game has this line somewhere.

**Clamping.** After moving, `math.max(min, math.min(max, x))` pins the position inside the viewport. This replaces breakout's wall entities entirely. Walls made sense there because the ball needed to *bounce* — real physics. Here we just want "can't go further," and that's one line of math.

**Two sizes.** `r` is the hitbox radius, and it's tiny. `DRAW_SIZE` is what you see. Shmups nearly all do this. The ship you see is what you steer, but the thing a bullet has to actually touch is a few pixels in the middle. It's what makes threading a bullet pattern feel fair instead of arbitrary. The little circle drawn on the ship is the hitbox; it's there so you can see it while you're learning.

## The stage

`game/stage.lua`:

```lua
local C = require('constants')
local new_player = require('entities.player')

return function()
  local stage = {
    player = new_player(C.VIEW_W / 2, C.VIEW_H - 80),
  }

  function stage:update(dt)
    self.player:update(dt)
  end

  function stage:draw()
    self.player:draw()
  end

  return stage
end
```

Small for now. It'll grow every chapter.

## Play, for real

`states/play.lua`:

```lua
local Gamestate = require('lib.hump.gamestate')
local new_stage = require('game.stage')

local play = {}

function play:enter()
  self.stage = new_stage()
end

function play:update(dt)
  self.stage:update(dt)
end

function play:draw()
  self.stage:draw()
end

function play:keypressed(key)
  if key == 'p' then
    Gamestate.push(require('states.pause'))
  end
end

return play
```

The fake `g` key is gone. `enter` builds a stage, `update` and `draw` delegate to it. That's all a scene should ever be.

## Checkpoint

Run it. Fly around. Try to leave the screen. Hold a diagonal and confirm it doesn't feel faster than straight. Pause still works: `p` pauses and the ship freezes.

## Exercises

- The clamp uses `DRAW_SIZE` rather than `r`. What happens if you use `r`? Which looks right?
- Add a `focus` mode: while `lshift` is held, halve the speed. (Real shmups do this; the slow speed is for dodging.)
