-- MAIN FILE - ttt-tournament-scoring

-- Define scoring table
-- ttt already defines SCORE let's use TOURNAMENT to avoid confusion in namespace
TOURNAMENT = {}
TOURNAMENT.totalRounds = 0
TOURNAMENT.sessionRounds = 0
TOURNAMENT.nonplayers = {}

-- Messing with the player metatable following ttt
-- In here we extend the metatable to track round performance
include("player_ext.lua")     -- Serverside
include("player_ext_shd.lua") -- Shared


-- Round end handling, team scores etc.
include("round_end.lua")
