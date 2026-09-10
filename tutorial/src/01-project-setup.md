# Project setup

The game lives at the repo root, next to `tutorial/`. Every path below is relative to that root, and `love .` from there runs it.

## Window config

Same idea as breakout: fix the window size so every number in the tutorial means the same thing on your screen as it did on mine.

`conf.lua`:

```lua
function love.conf(t)
  t.window.title = 'shmup'
  t.window.width = 800
  t.window.height = 600
  t.window.resizable = false
end
```

## Constants

Breakout read the window size with `love.window.getMode()` inside an entity. That's fine for one paddle, but a shmup has a lot of things that care about the edges of the screen — the player clamps to them, bullets die past them, power-ups bounce off them. Put the numbers in one place.

`constants.lua`:

```lua
return {
  VIEW_W = 800,
  VIEW_H = 600,
  -- how far past the edge something can go before we throw it away
  OFFSCREEN_MARGIN = 40,
}
```

The margin is the interesting one. An enemy at `y = -1` is still on its way in and shouldn't be thrown away. An enemy at `y = -400` is never coming back. Forty pixels is a comfortable "definitely gone."

## A first main.lua

Just enough to prove the window opens:

`main.lua`:

```lua
local C = require('constants')

function love.draw()
  love.graphics.printf('SHMUP', 0, C.VIEW_H / 2, C.VIEW_W, 'center')
end
```

Run it with `love .`. You should see the word SHMUP, centered, and nothing else. `printf` is `print` with a width and an alignment; we pass the full view width and `'center'` and let it do the math.

## Get hump.gamestate

Next chapter needs it. [hump](https://github.com/vrld/hump) is a grab-bag of small LÖVE helpers by Matthias Richter; we only want one file. Download `gamestate.lua` from the repo and put it at `lib/hump/gamestate.lua`:

```
love-shmup/
  conf.lua
  constants.lua
  main.lua
  lib/
    hump/
      gamestate.lua
```

Because `require` maps dots to directory separators, that file will be `require('lib.hump.gamestate')`. Breakout used slashes (`require('entities/boundary')`) — both work in LÖVE, but dots are the Lua convention and it's what this tutorial uses.

## Checkpoint

Window opens, says SHMUP, closes cleanly. That's the whole chapter.
