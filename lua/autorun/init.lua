-- MAIN FILE - ttt-tournament-scoring

TOURNAMENT = {}
TOURNAMENT.DEBUG = CreateConVar("tttt_debug",1,FCVAR_NONE,"Debug TTT Tournament Scoring",0,1)


-- Extra Utils
include("tttt_util.lua")


-- Player roles
ROLE_INNOCENT = 0
ROLE_TRAITOR = 1
ROLE_DETECTIVE = 2
ROLE_MERCENARY = 3
ROLE_JESTER = 4
ROLE_PHANTOM = 5
ROLE_HYPNOTIST = 6
ROLE_GLITCH = 7
ROLE_ZOMBIE = 8
ROLE_VAMPIRE = 9
ROLE_SWAPPER = 10
ROLE_ASSASSIN = 11
ROLE_KILLER = 12
ROLE_NONE = ROLE_INNOCENT

WIN_NONE = 1
WIN_TRAITOR = 2
WIN_INNOCENT = 3
WIN_TIMELIMIT = 4
WIN_JESTER = 5
WIN_KILLER = 6



-- Define scoring table
-- ttt already defines SCORE let's use TOURNAMENT to avoid confusion in namespace
TOURNAMENT.allScores = {}
TOURNAMENT.allScores.meta = {totalRounds = 0}
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

-- If player not in tournament table then add player to the tournament table
function addToTournament(ply)
  util.ttttDebug("TTTT DEBUG: Add new player to the tournament score table " .. ply:AccountID())
  -- Check if that SteamID already in the allScores.players table
  if not TOURNAMENT.allScores.players[ply:AccountID()] then
      -- WARNING players must have a valid global_score table before doing this. Make sure to create when
      -- joining the server.
      if not ply.global_score then
        util.ttttDebug("TTTT DEBUG: " .. ply:AccountID() .. " is a noob. has no global score... initialising...")
        ply.initGlobalScoreTable()
      end
      TOURNAMENT.allScores.players[ply:SteamID()] = ply.global_score
      print("Player" .. ply:AccountID() .. "added to tournament scoring table.")
      util.ttttDebug("Player" .. ply:AccountID() .. "added to tournament scoring table.")
  end
end

-- Maybe we move all the save load stuff to its own file...
-- Read in the scores from the JSON file
function readScoresFromDisk()

    util.ttttDebug("TTTT DEBUG: Attempting to load data")

    local data = file.Read("playerdata.json", "DATA")
    -- If the file  exists, read it, else give empty JSON to return as a table.
    if data then
      util.ttttDebug("TTTT DEBUG: Data file found... loading...")
      util.ttttDebug("TTTT DEBUG: Loaded saved data from disk")
    else
      print("No saved tournament data found. Initialising new data")
      data = "{\"meta\":{\"totalRounds\":0}}"
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
    -- Also update player global score tables to match tournament score table

    --util.ttttDebug("TTTT DEBUG: Add players to tournament scoring table")
    --util.ttttDebug("TTTT DEBUG: Move data from disk scores to player metatable")
    --for k,v in pairs(player.getAll()) do
    --    addToTournament(v)
    --    v.global_score = TOURNAMENT.allScores.players[v:SteamID()]
    --end
  
    
    -- We now have all of the file containing the score history stored in both PlyMeta.global_score tables
    -- and also in TOURNAMENT.allScores.players[STEAM_ID], this isn't great but let's see what happens
  
  end


  gameevent.Listen( "player_connect" )
  hook.Add("player_connect", "AnnounceConnection", function( data )
    local newply = Entity(data.index)
    addToTournament(newply)
    newply.global_score = TOURNAMENT.allScores.players[newply:SteamID()]
  end)
  
function ttttDefineRoles()

  util.ttttDebug("TTTT DEBUG: Defining roles because lua load order is nonsense")
  TOURNAMENT.TEAM_INNOCENT = {
      [ROLE_INNOCENT] = true,
      [ROLE_DETECTIVE] = true,
      [ROLE_MERCENARY] = true,
      [ROLE_PHANTOM] = true,
      [ROLE_GLITCH] = true
  }

  TOURNAMENT.TEAM_TRAITOR = {
      [ROLE_TRAITOR] = true,
      [ROLE_VAMPIRE] = true,
      [ROLE_HYPNOTIST] = true,
      [ROLE_ZOMBIE] = true,
      [ROLE_ASSASSIN] = true
  }

  TOURNAMENT.TEAM_JESTER = {
      [ROLE_JESTER] = true,
      [ROLE_SWAPPER] = true
  }

  -- Table for tracking what win conditions mean for
  -- different roles in the game
  TOURNAMENT.winComp = {
    [WIN_INNOCENT] = TOURNAMENT.TEAM_INNOCENT,
    [WIN_TRAITOR] = TOURNAMENT.TEAM_TRAITOR,
    [WIN_JESTER] = TOURNAMENT.TEAM_JESTER,
    [WIN_KILLER] = {
        [ROLE_KILLER] = true
    },
    [WIN_TIMELIMIT] = TOURNAMENT.TEAM_INNOCENT
  }

end
  
  -- Functions to run when the server begins (GM:Initialize hook), namespacing this thing
function TOURNAMENT.serverInit()
    
    util.ttttDebug("TTTT DEBUG: Server initialisation...")
    util.ttttDebug("TTTT DEBUG: TTT Tournament Scoring is loaded and in debug") 
    ttttDefineRoles()
    
    -- Read Scores table from disk
    util.ttttDebug("TTTT DEBUG: Attempt to load data")
    readScoresFromDisk()
    
end

  -- Add serverInit function to gamemode initialisation
hook.Add("Initialize", "TournamentServerInit", TOURNAMENT.serverInit)

concommand.Add( "reruninit", TOURNAMENT.serverInit )

