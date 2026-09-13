local collision = {}

function collision.overlaps(a, b)
  local dx, dy = a.x - b.x, a.y - b.y
  local reach = a.r + b.r
  return dx * dx + dy * dy < reach * reach
end

function collision.each_pair(list_a, list_b, on_hit)
  for _, a in ipairs(list_a) do
    if not a.dead then
      for _, b in ipairs(list_b) do
        if not b.dead and collision.overlaps(a, b) then
          on_hit(a, b)
        end
      end
    end
  end
end

function collision.each_against(one, list, on_hit)
  if one.dead then return end

  for _, b in ipairs(list) do
    if not b.dead and collision.overlaps(one, b) then
      on_hit(one, b)
    end
  end
end

return collision
