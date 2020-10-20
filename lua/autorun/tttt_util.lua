-- Utilities for TTT Tournament Scoring

if not util then return end

-- Return boolean as 1 or 0 integer
function util.bool2num(val)
    return (val and 1 or 0)
end