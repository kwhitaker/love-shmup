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
