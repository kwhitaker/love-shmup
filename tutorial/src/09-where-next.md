# Where next

Five hundred lines of Lua and a working shmup. Here's what the structure is ready for, roughly in the order you'd want it.

## Things you'll need soon

**Waves instead of a random timer.** The spawner is the obvious place. The simplest version is a table of `{ at = seconds, x = ..., pattern = ... }` and a cursor that walks it. The good version is a coroutine: a function that yields between spawns, so a wave reads top to bottom like a script. Spawn five, wait two seconds, spawn a weaver, wait. Lua's coroutines are made for this. `hump.timer` has a `script` helper that wraps the pattern if you'd rather not roll it.

**Boss with phases.** Same coroutine idea, one long function. Or a small state machine on the entity: a table of `{ enter, update }` per phase and a `set(phase)` method. Both are standard; the coroutine reads better for sequences, the state machine for anything that reacts.

**Sound and particles.** The stage currently knows when an enemy dies, because the collision callback is right there. It shouldn't have to know that death makes a noise. `hump.signal` (or `beholder`) gives you `signal.emit('enemy_died', enemy)` and lets the sound module and the particle module subscribe. Use it for cross-cutting stuff like this; don't route the core loop through it.

**Screen scaling.** Everything is hardcoded to 800×600. The `push` library, or a `love.graphics.scale` in `love.draw`, gives you a virtual resolution the game draws to and a window that can be any size. Do this before adding art.

## Things you'll need eventually

**Object pool for bullets.** Right now every bullet is a new table and the sweep drops it for the garbage collector. LuaJIT handles a few hundred per second without noticing. A bullet-hell pattern spawning thousands will notice. The fix is a pool of dead bullets you reuse. Measure first.

**Spatial partitioning.** `each_pair` is every-against-every. With 50 enemies and 200 bullets that's 10,000 checks a frame, which is still fine. Past that, a grid (bucket entities by cell, only check neighbors) or the `bump.lua` library. Again: measure first.

**Fixed timestep.** Right now `dt` is whatever the frame took, so two runs with identical inputs won't produce identical games. If you ever want replays or a deterministic bullet pattern, `update` needs to run in fixed slices: accumulate `dt`, step in 1/60s chunks. Retrofitting this is painful, so decide early.

**Bitmask layers.** When five lists becomes ten, the pairs table gets awkward and it's time for each entity to carry a layer and a mask. learn2love's *Binary and bitmasks* chapter is the setup for exactly that.

## Things worth reading

- Robert Nystrom, [*Game Programming Patterns*](https://gameprogrammingpatterns.com/), free online. State, Update Method, Object Pool, and Observer are the four chapters this tutorial has been quietly leaning on.
- The [LÖVE wiki](https://love2d.org/wiki/Main_Page), the actual API reference. `love.graphics`, `love.math.random`, `love.keyboard.isDown`.
- [hump](https://hump.readthedocs.io/), the rest of the library. `timer` and `signal` are the next two you'd pull in.
- [Programming in Lua](https://www.lua.org/pil/contents.html), the coroutine chapter especially.
