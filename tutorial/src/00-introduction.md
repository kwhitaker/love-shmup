# Introduction

This is a short tutorial for building a vertical shmup (shoot 'em up: you're a tiny ship, everything else on screen wants you dead) in [LÖVE](https://love2d.org) and Lua. Simple shapes, no sprites, no sound. By the end you'll have a ship that flies, fires, dies, respawns, and eventually runs out of lives, plus enemies, bullets in both directions, and a bouncing power-up.

## A note on where this came from

The text and code here were generated with Claude, from a conversation about how to structure a shmup in LÖVE. The exercise runs the other way, though: **you type everything by hand.** The goal is to learn Lua, LÖVE, and a handful of game-programming habits that show up in every genre. Copy-paste teaches you where the clipboard is.

Type each file out. Run the game at every checkpoint. When something breaks, read the error before reading the tutorial. That's most of the learning.

## Do learn2love first

This assumes you've worked through [learn2love](https://rvagamejams.com/learn2love/), at least chapter 2 (*Introducing LÖVE*) through the Breakout project. It picks up where that leaves off: you know what `love.update` and `love.draw` are, you've written a `conf.lua`, you've split code into modules with `require`, and you've made a breakout clone with Box2D. If any of that is fuzzy, go do that first. It's a better introduction than anything here.

## What's different from breakout

Breakout leaned on `love.physics` (Box2D) because a ball that bounces convincingly is exactly what a physics engine is for. A shmup is not. Nothing bounces. Bullets don't push enemies around. Collision means "did these two things overlap, yes or no." So this tutorial drops Box2D entirely and does movement and collision by hand, a few lines of arithmetic per entity. That's the standard choice for the genre, and a good way to see what a physics engine was doing for you.

The other new thing is scenes. Breakout had a single `main.lua` with `game_over` and `paused` flags. Here there's a menu, the game, a pause screen, and a game-over screen, managed by a small library called `hump.gamestate`. Chapter 2 covers it.

## What we're building

- **Game world:** new game, pause/resume, game over, restart
- **Player:** free movement inside the viewport, constant fire on a timer, health, lives, respawn with a grace period, game over when lives run out
- **Enemies:** spawned on a timer, a couple of movement patterns, fire at the player, one hit point
- **Power-up:** bounces around the screen for a while, speeds up the player's fire rate on pickup, then gives up and drifts offscreen

Every chapter ends with a runnable game. Every chapter's code is the complete file — if you're stuck, diff yours against it.

## Reading this book

It's an [mdbook](https://rust-lang.github.io/mdBook/). From the repo root:

```
mdbook serve tutorial --open
```

It live-reloads when the source changes, so keep it in a browser tab next to your editor.
