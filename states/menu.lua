local Gamestate = require('lib.hump.gamestate')
local C = require('constants')

local menu = {}

function menu:draw()
  love.graphics.printf('SHMUP', 0, C.VIEW_H / 2 - 40, C.VIEW_W, 'center')
  love.graphics.printf('press enter to start', 0, C.VIEW_H / 2, C.VIEW_W, 'center')
end

function menu:keypressed(k)
  if k == 'return' then
    Gamestate.switch(require('states.play'))
  end
end

return menu
