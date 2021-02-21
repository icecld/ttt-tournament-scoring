-- MAIN FILE - ttt-tournament-scoring

TOURNAMENT = {}
TOURNAMENT.version = 1.1
TOURNAMENT.DEBUG = CreateConVar("tttt_debug",1,FCVAR_NONE,"Debug TTT Tournament Scoring",0,1)

-- Extra Utils
include("tttt_util.lua")

-- Define scoring table
-- ttt already defines SCORE let's use TOURNAMENT to avoid confusion in namespace
TOURNAMENT.allScores = {}
TOURNAMENT.allScores.players = {}
TOURNAMENT.allScores.meta = {totalRounds = 0, totalPlayers = 0}
TOURNAMENT.sessionRounds = 0
TOURNAMENT.nonPlayers = {}
TOURNAMENT.BaseScore = 10
TOURNAMENT.BoringWeapons = {}
TOURNAMENT.FirstInit = false
TOURNAMENT.sharedAttributes = {"totalScore", "traitorKills", "innocentKills", "killerKills", "jesterKills", "ownTeamKills", "suicides", "fallDeaths", "totalKills", "totalDeaths"}

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

util.ttttDebug("Defining roles because lua load order is nonsense")
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


-- Messing with the player metatable following ttt
-- In here we extend the metatable to track round performance
include("player_ext.lua")     -- Serverside
include("player_ext_shd.lua") -- Shared

--Handling intra-round scoring based on players' acions, e.g. innocent killed a traitor
include("individual_scoring.lua")

-- Round end handling, team scores etc.
include("round_end.lua")
include("round_start.lua")


-- If player not in tournament table then add player to the tournament table
function TOURNAMENT:AddToTournament(ply)
  util.ttttDebug("Add new player to the tournament score table " .. ply:Name())
      -- WARNING players must have a valid global_score table before doing this. Make sure to create when
      -- joining the server.
      util.ttttConsoleMsg("" .. ply:Name() .. " is a noob. Has no global score: initialising their score table...")

      TOURNAMENT.allScores.players[ply:SteamID()] = ply.global_score
      TOURNAMENT.allScores.meta.totalPlayers = TOURNAMENT.allScores.meta.totalPlayers + 1

      util.ttttConsoleMsg("Player " .. ply:Name() .. " added to tournament scoring table. Their data will be saved a the end of the next round.")
end

-- Maybe we move all the save load stuff to its own file...
-- Read in the scores from the JSON file
function TOURNAMENT:ReadScoresFromDisk()

    util.ttttConsoleMsg("Attempting to load data")

    local loadedData = file.Read("tournamentscoring/playerdata.json", "DATA")
    -- If the file  exists, read it, else give empty JSON to return as a table.
    if loadedData then
      util.ttttConsoleMsg("Data file found... loading...")
      util.ttttConsoleMsg("Loaded saved data from disk")
    else
      util.ttttConsoleMsg("No saved tournament data found. Initialising new data")
      --local data = "{\"meta\":{\"totalRounds\":0}}"
      loadedData = "{\"meta\":{\"totalRounds\":0, \"totalPlayers\":0},\"players\":[]}"
    end

    local tableFromDisk = util.JSONToTable(loadedData)
  
    -- Bring full table into memory
    TOURNAMENT.allScores = tableFromDisk
  end

gameevent.Listen( "PlayerAuthed" )
hook.Add("PlayerAuthed", "PlayerConnectionHandler", function(ply, steamid, uniqueid)
  if SERVER then
    util.ttttDebug("New Player Connected: " .. ply:Name())
    ply:initGlobalScoreTable()
    ply:initSessionScoreTable()
    ply:initRoundScoreTable()
    if TOURNAMENT.allScores.players[ply:SteamID()] ~= nil then
      ply.global_score = TOURNAMENT.allScores.players[ply:SteamID()]

      -- Check to see if they changed their nickname and update if needed
      if ply:Name() ~= TOURNAMENT.allScores.players[ply:SteamID()].nick then

        local oldnick = TOURNAMENT.allScores.players[ply:SteamID()].nick
        TOURNAMENT.allScores.players[ply:SteamID()].nick = ply:Name()
        util.ttttConsoleMsg("Updated " .. ply:Name() .. "'s nickname due to mismatch: " .. oldnick .. " -> " .. ply:Name())

      end
      util.ttttAnnounce("Welcome back, " .. ply:Name() .. ". Fun Fact: " .. ply:funfact())
    else
      -- First time we've seen this player - add the player to the tournament
      TOURNAMENT:AddToTournament(ply)
    end
  end
end)


  
  -- Functions to run when the server begins (GM:Initialize hook), namespacing this thing
function TOURNAMENT:serverInit()

  if SERVER then

    util.ttttConsoleMsg("A probably buggy mod by icecold.trashcan & trogdip, version " .. TOURNAMENT.version)
    util.ttttDebug("TTT Tournament Scoring is loaded and in debug")
    --ttttDefineRoles()

    -- Read Scores table from disk
    TOURNAMENT:ReadScoresFromDisk()
    TOURNAMENT.FirstInit = true
  end

end

  -- Add serverInit function to gamemode initialisation
hook.Add("Initialize", "TournamentServerInit", TOURNAMENT.serverInit)

function TOURNAMENT:allTimeScoreboard()
  local rankedPlayers = {}
  
  for sid, player in pairs(TOURNAMENT.allScores.players) do
    table.insert(rankedPlayers, {id = sid, score = player.totalScore})
  end
  
  table.sort(rankedPlayers, function(a,b) return a.score > b.score end)
  for k,ply in pairs(player.GetAll()) do
    ply:PrintMessage( HUD_PRINTTALK, ("ALL TIME SCORES"))
    for i, rply in ipairs(rankedPlayers) do
      ply:PrintMessage( HUD_PRINTTALK, (TOURNAMENT.allScores.players[rply.id].nick .. ": " .. TOURNAMENT.allScores.players[rply.id].totalScore))
    end
    ply:PrintMessage( HUD_PRINTTALK, "Fun Fact: " .. ply:funfact())
  end
end

concommand.Add( "reruninit", TOURNAMENT.serverInit )

concommand.Add( "tscore", function(ply, cmd, args)  
	p = ents.FindByName(args[1])
  for k,v in pairs(player.GetAll()) do
    print(v.global_score.totalScore)
  end
end)

concommand.Add( "tawardscore", function(ply, cmd, args)
	local awardedply = util.ttttGetPlayerFromName(args[1])
  local score = args[2]
  awardedply.global_score.totalScore = awardedply.global_score.totalScore + score
  awardedply:PrintMessage( HUD_PRINTTALK, "You have been given " .. (score) .. " points by " .. ply:GetName() .. "!" )
end)

concommand.Add( "printplayertable", function(ply, cmd, args)
	local ply = util.ttttGetPlayerFromName(args[1])
  PrintTable(ply.round_score)
end)

concommand.Add( "tsave", function(ply, cmd, args)  
    TOURNAMENT.WriteScoresToDisk()
end)

concommand.Add( "tprintglobaltable", function(ply, cmd, args)  
  PrintTable(TOURNAMENT)
end)

concommand.Add( "tscoreboard", function(ply, cmd, args)  
  --for k,ply in pairs(player.GetAll()) do
  --  ply:reportRoundScore()
  --end
  TOURNAMENT:allTimeScoreboard()
end)

concommand.Add( "tfunfact", function(ply, cmd, args)
  for k,ply in pairs(player.GetAll()) do
    util.ttttAnnounce(ply:Name() .. ": " .. ply:funfact())
  end
end)

concommand.Add( "test", function(ply, cmd, args)  
	--print("First player has " .. TOURNAMENT.allScores.players[1].totalScore .. " points!")
  --print(TOURNAMENT.allScores.players["STEAM_0:0:43907269"].totalScore)
  --announcePoints()
  --writeScoresToDisk()
  TOURNAMENT.FirstInit = true
end)