# Scenes with hump.gamestate

Breakout kept `paused`, `game_over` and `stage_cleared` as flags in a shared state table, and `love.update` checked them and bailed early. That works for three flags. It gets ugly at five, and it never gets you a menu.

The usual answer is a gamestate (or scene, or screen; every framework names it differently). A gamestate is a table with the same callbacks LÖVE has (`update`, `draw`, `keypressed`) and a small library that decides which table currently receives them. Only one scene is active at a time. Switching from the menu to the game is switching which table is on top.

## The library

`hump.gamestate` is about a hundred lines. Four functions matter:

- **`Gamestate.registerEvents()`** wraps every `love.*` callback so it forwards to the current state. Call it once in `love.load`.
- **`Gamestate.switch(to, ...)`** replaces the current state. Calls `leave()` on the old one, then `enter(previous, ...)` on the new one.
- **`Gamestate.push(to, ...)`** puts a state on top of the current one. The old state stays in memory but stops receiving callbacks. Pause, basically.
- **`Gamestate.pop()`** removes the top state. The one underneath gets `resume()`.

A state table can define any of `init`, `enter`, `leave`, `resume`, `update`, `draw`, and any LÖVE input callback. All optional. `init` runs once ever, the first time a state is entered; `enter` runs every time. Level setup goes in `enter`; you'll see why when we get to restart.

## main.lua

```lua
local Gamestate = require('lib.hump.gamestate')
local menu = require('states.menu')

function love.load()
  Gamestate.registerEvents()
  Gamestate.switch(menu)
end
```

That's the whole file now, and it stays this size for the rest of the tutorial. Everything else lives in a state.

## The menu

`states/menu.lua`:

```lua
local Gamestate = require('lib.hump.gamestate')
local C = require('constants')

local menu = {}

function menu:draw()
  love.graphics.printf('SHMUP', 0, C.VIEW_H / 2 - 40, C.VIEW_W, 'center')
  love.graphics.printf('press enter to start', 0, C.VIEW_H / 2, C.VIEW_W, 'center')
end

function menu:keypressed(key)
  if key == 'return' then
    Gamestate.switch(require('states.play'))
  end
end

return menu
```

Two things to notice. First, the state is a plain table and the callbacks are methods on it. `function menu:draw()` is sugar for `menu.draw = function(self)`, and hump calls them with the state as `self`. Second, `require('states.play')` happens inside `keypressed`, not at the top of the file. That's deliberate: `play` will eventually require `gameover`, which requires `menu`, which requires `play`. Lua handles circular requires badly. Requiring lazily, at the moment of the switch, sidesteps it.

## Play, as a placeholder

The real game comes next chapter. For now `play` just counts seconds so we can see that switching works, and fakes a game-over on the `g` key so we can test the whole loop:

`states/play.lua`:

```lua
local Gamestate = require('lib.hump.gamestate')
local C = require('constants')

local play = {}

function play:enter()
  self.seconds = 0
end

function play:update(dt)
  self.seconds = self.seconds + dt
end

function play:draw()
  love.graphics.printf(('playing for %.1fs'):format(self.seconds), 0, C.VIEW_H / 2, C.VIEW_W, 'center')
end

function play:keypressed(key)
  if key == 'p' then
    Gamestate.push(require('states.pause'))
  elseif key == 'g' then
    Gamestate.switch(require('states.gameover'), self.seconds)
  end
end

return play
```

`enter` resets the counter. Try it: play, hit `g`, hit enter to retry. The counter starts from zero because `enter` ran again. That's restart, for free. Next chapter `enter` builds the entire stage, and restart still costs nothing.

## Pause

`states/pause.lua`:

```lua
local Gamestate = require('lib.hump.gamestate')
local C = require('constants')

local pause = {}

function pause:enter(from)
  self.from = from
end

function pause:draw()
  self.from:draw()
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle('fill', 0, 0, C.VIEW_W, C.VIEW_H)
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf('PAUSED', 0, C.VIEW_H / 2, C.VIEW_W, 'center')
end

function pause:keypressed(key)
  if key == 'p' then
    Gamestate.pop()
  end
end

return pause
```

`enter` receives the state that was active before (hump passes it as the first argument) and we keep it. Then `draw` calls the previous state's `draw` before darkening the screen. Without that line, pause is a black screen with PAUSED on it, which is technically correct and looks broken.

Note what we don't do: nothing tells `play` to stop updating. It just isn't the top of the stack anymore, so hump doesn't call its `update`. When we `pop`, it resumes with the same `self.seconds` it had. The pause flag from breakout is gone and nothing replaced it.

## Game over

`states/gameover.lua`:

```lua
local Gamestate = require('lib.hump.gamestate')
local C = require('constants')

local gameover = {}

function gameover:enter(_, score)
  self.score = score
end

function gameover:draw()
  love.graphics.printf('GAME OVER', 0, C.VIEW_H / 2 - 40, C.VIEW_W, 'center')
  love.graphics.printf(('score: %d'):format(self.score), 0, C.VIEW_H / 2, C.VIEW_W, 'center')
  love.graphics.printf('enter to retry, escape for menu', 0, C.VIEW_H / 2 + 40, C.VIEW_W, 'center')
end

function gameover:keypressed(key)
  if key == 'return' then
    Gamestate.switch(require('states.play'))
  elseif key == 'escape' then
    Gamestate.switch(require('states.menu'))
  end
end

return gameover
```

`switch` takes extra arguments after the state and passes them to `enter` after `previous`. That's how the score gets here. The underscore is Lua convention for "there's an argument here and I don't want it."

## Checkpoint

Run it. Enter starts, `p` pauses and unpauses, `g` ends the game, enter restarts, escape goes back to the menu. Watch the counter: it should freeze under pause and reset after retry.

## Exercises

- Add a `leave` to `play` that prints something. When does it fire on pause? On game over? Why the difference?
- Make escape from the pause screen go to the menu directly instead of back to the game.
