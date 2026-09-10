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
