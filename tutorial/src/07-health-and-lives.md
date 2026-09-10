# Health, lives, game over

Time to make getting hit mean something, and then keep it from meaning too much. A shmup that respawns you into the bullet that killed you eats all three lives in a second.

## The player

`entities/player.lua`:

```lua
local C = require('constants')

local new_bullet = require('entities.bullet')

local SPEED = 320
local RADIUS = 6      -- hitbox, deliberately tiny
local DRAW_SIZE = 16  -- what you actually see
local BULLET_SPEED = 600
local BULLET_COLOR = { 0.4, 0.9, 1 }
local MAX_HEALTH = 3
local START_LIVES = 3
local INVULN_TIME = 2

return function(x, y)
  local player = {
    x = x,
    y = y,
    r = RADIUS,
    dead = false,
    fire_interval = 0.2,
    cooldown = 0,
    health = MAX_HEALTH,
    lives = START_LIVES,
    invuln = 0,
    spawn_x = x,
    spawn_y = y,
  }

  function player:update(dt, stage)
    self.invuln = math.max(0, self.invuln - dt)

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

  function player:hit(damage)
    if self.invuln > 0 then return end
    self.health = self.health - damage
    if self.health <= 0 then
      self:lose_life()
    end
  end

  function player:lose_life()
    self.lives = self.lives - 1
    if self.lives <= 0 then
      self.dead = true
      return
    end
    self.health = MAX_HEALTH
    self.invuln = INVULN_TIME
    self.x, self.y = self.spawn_x, self.spawn_y
  end

  function player:draw()
    -- blink while invulnerable so the respawn reads on screen
    if self.invuln > 0 and math.floor(self.invuln * 10) % 2 == 0 then
      return
    end
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

**`hit` and `lose_life`.** Same shape as the enemy's `hit`, plus one more layer. Health hits zero, you lose a life. Lives hit zero, `dead` goes true, and that's the only thing that ever sets it. The stage reads that flag to decide the round is over.

**Invulnerability.** `invuln` is a timer that starts at two seconds on respawn and counts down in `update`. While it's above zero, `hit` returns early. Without this, respawning drops you into whatever pattern killed you and you lose all three lives in half a second. Every shmup does this, usually with a blink so the player can see it happening, which is why `draw` bails out on alternating tenths of a second while the timer runs. `math.floor(self.invuln * 10) % 2` flips between 0 and 1 ten times a second.

**Respawn position.** The factory stores the spawn point it was given. Respawning is just going back there.

Note what `hit` does *not* do: it doesn't touch the stage, doesn't switch scenes, doesn't know that game over exists. It changes numbers on itself. That's what keeps this file readable.

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
    spawner = new_spawner(),
    score = 0,
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
    self.player:draw()
    self:draw_hud()
  end

  return stage
end
```

The two print statements from last chapter become `player:hit(1)`. There's a score now, up 100 per kill. The check is `if enemy.dead` *after* `hit`, so it only counts when this bullet was the one that finished it. And a HUD, drawn last so it sits on top of everything.

`is_over` is one line. It could be inlined in `play`, but having the stage answer "is this round done" keeps `play` from knowing anything about players or lives.

## Ending the round

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
  if self.stage:is_over() then
    Gamestate.switch(require('states.gameover'), self.stage.score)
  end
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

The pattern to remember: **check for the transition after the update, not during it.** The stage runs a full frame, then `play` asks whether it's over. The alternative, switching scenes from inside the collision callback mid-loop, leaves half a frame of entities un-updated and, if you're using a physics library, usually crashes. Let the frame finish. Then leave.

The score gets passed through `switch` to `gameover:enter`, which was already written to receive it back in chapter 2.

## Checkpoint

Run it. Take three hits: health drops, then you blink for two seconds back at the start position with one life fewer. Lose all three and it's the game-over screen with your score. Enter to retry: fresh stage, three lives, score zero.

Notice that enemy bullets still die when they hit a blinking player. That's deliberate: if they passed through, a ship sitting still in a bullet stream would take the hit the instant the timer ran out. The invulnerable ship absorbs bullets.

## Exercises

- Draw health as three small rectangles instead of a number.
- Give the player a brief invulnerability on every hit, not just respawn. A quarter of a second. Does it change how the game feels?
- Show the high score on the game-over screen. Where does it have to live to survive a `switch`? (Hint: not in `play:enter`.)
