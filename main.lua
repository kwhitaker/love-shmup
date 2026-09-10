local Gamestate = require('lib.hump.gamestate')
local menu = require('states.menu')

function love.load()
  Gamestate.registerEvents()
  Gamestate.switch(menu)
end
