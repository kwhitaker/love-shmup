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
