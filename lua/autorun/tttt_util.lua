-- Utilities for TTT Tournament Scoring

if not util then return end

-- Return boolean as 1 or 0 integer
function util.bool2num(val)
    return (val and 1 or 0)
end

-- Count the key/val pairs in a table. Why is this not a basic funciton of LUA? Why?
function util.tableLen(tab)
  local n
  for k,v in pairs(tab) do
    n = n + 1
  end
  return n
end
