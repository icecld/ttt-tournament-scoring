-- MAIN FILE - ttt-tournament-scoring

-- Define scoring table
-- ttt already defines SCORE let's use TOURNAMENT to avoid confusion in namespace
TOURNAMENT = {}
TOURNAMENT.allScores.meta.totalRounds = 0
TOURNAMENT.sessionRounds = 0
TOURNAMENT.nonplayers = {}

-- Messing with the player metatable following ttt
-- In here we extend the metatable to track round performance
include("player_ext.lua")     -- Serverside
include("player_ext_shd.lua") -- Shared

--Handling intra-round scoring based on players' acions, e.g. innocent killed a traitor
include("individual_scoring.lua")

-- Round end handling, team scores etc.
include("round_end.lua")


-- Maybe we move all the save load stuff to its own file...
-- Read in the scores from the JSON file
function readScoresFromDisk()

    -- If the file  exists, read it, else give empty JSON to return as a table.
    if file.Exists("playerdata.json", "tournamentscoring") == true then
      local data = file.Read("playerdata.json", "tournamentscoring")
    else
      PrintMessage(HUD_PRINTCONSOLE, "No saved tournament data found.")
      local data = "{}"
    end
  
    local tableFromDisk = util.JSONToTable(data)
  
    -- search table for the currently online players and recall their saved scores
    -- then make a list of the offline players so they don't get overwritten next time
  
    -- ** @Tim: is there a more efficient way to do this without having to have nested iteratations
    -- that linear search both the recalled and online players tables for matching IDs?
    -- ** @George: I think it will work better to store the whole of the disk score file in memory,
    -- update and write out as needed
  
    -- Bring full table into memory
    TOURNAMENT.allScores = tableFromDisk
  
    -- Using Steam ID as Key in TOURNAMENT.allSocres will allow non-conflicting access
    -- Add any new players to this score table, must call when player joins as well
    for k,v in pairs(player.getAll())
        addToTournament(v)
    end
  
    -- Update player global score tables to match tournament score table
    for k,v in pairs(player.getAll())
        v.global_score = TOURNAMENT.allScores.players[v:SteamID()]
    end
  
    -- We now have all of the file containing the score history stored in both PlyMeta.global_score tables
    -- and also in TOURNAMENT.allScores.players[STEAM_ID], this isn't great but let's see what happens
  
  end
  
  -- Functions to run when the server begins (GM:Initialize hook), namespacing this thing
  function TOURNAMENT.serverInit()
    
    -- Read Scores table from disk
    readScoresFromDisk()
    
  end

  -- Add serverInit function to gamemode initialisation
  hook.Add("Initialize", "TournamentServerInit", TOURNAMENT.serverInit)