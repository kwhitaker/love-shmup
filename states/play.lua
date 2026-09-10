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

function play:keypressed(k)
  if k == 'p' then
    Gamestate.push(require('states.pause'))
  elseif k == 'g' then
    Gamestate.switch(require('states.gameover'), self.seconds)
  end
end

return play
