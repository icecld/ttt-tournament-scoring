-- Utilities for TTT Tournament Scoring

if not util then return end

-- Return boolean as 1 or 0 integer
function util.bool2num(val)
    return (val and 1 or 0)
end

function util.strInTable(tab, str)
  for i,v in ipairs(tab) do
    if v == str then
      return true
    end
  end
  return false
end

-- Count the key/val pairs in a table. Why is this not a basic funciton of LUA? Why?
function util.tableLen(tab)
  local n
  for k,v in pairs(tab) do
    n = n + 1
  end
  return n
end

-- If DEBUG then print debug messages
function util.ttttDebug(msg)
    --if SERVER then 
        if TOURNAMENT.DEBUG:GetBool() then 
          print("TTTT DEBUG: " .. msg)
        end
    --end
end

function util.ttttGetPlayerFromName(playerName)
  for i, ply in ipairs( player.GetAll() ) do
		if ply:GetName() == playerName then
      return ply
    end
	end
end