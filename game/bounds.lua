local C = require('constants')

local bounds = {}

-- true once an entity is far enough outside the viewport that nobody will miss it
function bounds.is_offscreen(e)
  local m = C.OFFSCREEN_MARGIN
  return e.x < -m or e.x > C.VIEW_W + m or e.y < -m or e.y > C.VIEW_H + m
end

-- remove dead and offscreen entities in place. walk backwards so removing
-- an element doesn't shift the ones we haven't looked at yet
function bounds.sweep(list)
  for i = #list, 1, -1 do
    local e = list[i]
    if e.dead or bounds.is_offscreen(e) then
      list[i] = list[#list]
      list[#list] = nil
    end
  end
end

return bounds
