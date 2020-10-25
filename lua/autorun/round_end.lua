-- Handle all the round end stuff in here, scoring plus saving

--Include Utilities

-- Table of Team Roles

TOURNAMENT.TEAM_INNOCENT = {
    [ROLE_INNOCENT] = true,
    [ROLE_DETECTIVE] = true,
    [ROLE_MERCENARY] = true,
    [ROLE_PHANTOM] = true,
    [ROLE_GLITCH] = true
}

TOURNAMENT.TEAM_TERROR = {
    [ROLE_TERROR] = true,
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
local TOURNAMENT.winComp = {
    [WIN_INNOCENT] = TOURNAMENT.TEAM_INNOCENT,
    [WIN_TERROR] = TOURNAMENT.TEAM_TERROR,
    [WIN_JESTER] = TOURNAMENT.TEAM_JESTER,
    [WIN_KILLER] = {
        [ROLE_KILLER] = true
    },
    [WIN_TIMELIMIT] = TOURNAMENT.TEAM_INNOCENT
}


-- Calculate baseline bonus for members of winning team
function calcTeamWinBonus(wintype)

    local win_bonus = 0

    -- Check who won and calculate team score
    if wintype == WIN_INNOCENT or wintype == WIN_TIMELIMIT then
        -- Innocents win - bonus = number of living players remaining
        -- Yes this will give a bonus for a living jester
        for k,v in pairs(player.getAll()) do
            win_bonus = win_bonus + util.bool2num(v:Alive)
        end
    elseif wintype == WIN_TERROR then
        -- Traitors get (num_killed)/(num_traitor-num_dead_traitor)

        num_killed = 0
        num_traitor = 0
        num_dead_traitor = 0
        -- For all players get required numbers, this should be replaced
        -- with online tracking of these values
        for k,v in pairs(player.getAll()) do
            -- If player role not in team traitor
            if TOURNAMENT.TEAM_TRAITOR[v:GetRole()] then
                -- How many traitors
                num_traitor = num_traitor + 1
                -- Is dead traitor
                if not v:Alive() then
                    num_dead_traitor = num_dead_traitor + 1
                end
            else
                -- If player is dead not traitor then increment
                num_killed = num_killed + bool2num(v:Alive)
            end
        end

        -- Calculate win bonus
        win_bonus = num_killed/(num_traitor-num_dead_traitor)

    elseif wintype == WIN_KILLER then
        -- Killer kills everyone, bonus = 1 per kill
        win_bonus = self.round_score["innocentKills"] + self.round_score["traitorKills"]
    elseif wintype == WIN_JESTER then
        -- Jester jests everyone, bonus = 1 per player on server
        win_bonus = player.GetCount()
    end

    return win_bonus

end


-- Hand out scores at end of round for team performance
function roundEndTeamScoring(win_type)


    -- Winning team base bonus
    local win_bonus = calcTeamWinBonus(win_type)


    -- For each player check if their team won and allocate points
    for k,v in pairs(player.getAll()) do

        -- If player role is a valid key in the table indexed by the win
        -- condition then award the win_bonus score to that player.
        if TOURNAMENT.winComp[win_type][v:GetRole()] == true then

            -- Calculate player modifer
            local score_modifier = 1

            -- Extra modifiers go here

            -- Half points for deados is final modifier
            if v:Alive() ~= true then score_modifier = score_modifier/2 end

            ply_score = win_bonus*score_modifier

            -- Give win bonus to player
            v:PrintMessage( HUD_PRINTTALK, "You have been awarded " .. (ply_score) .. " end of round points!" )
            v:awardScore(ply_score)
        end

    end

end

function roundEndIncrementCounters()
  --increment overall round counters
  TOURNAMENT.allScores.meta.totalRounds = TOURNAMENT.allScores.meta.totalRounds + 1
  TOURNAMENT.sessionRounds = TOURNAMENT.sessionRounds + 1

  --increment players' individual round counters, depending on which team they're on
  for k,v in pairs(player.getAll()) do

    v.global_score["totalRounds"] = v.global_score["totalRounds"] + 1
    v.session_score["totalRounds"] = v.session_score["totalRounds"] + 1

    if TOURNAMENT.TEAM_INNOCENT[v:GetRole()] then
      v.global_score["roundsPlayedAsInnocent"] = v.global_score["roundsPlayedAsInnocent"] + 1
      v.session_score["roundsPlayedAsInnocent"] = v.session_score["roundsPlayedAsInnocent"] + 1
    elseif TOURNAMENT.TEAM_TRAITOR[v:GetRole()] then
      v.global_score["roundsPlayedAsTraitor"] = v.global_score["roundsPlayedAsTraitor"] + 1
      v.session_score["roundsPlayedAsTraitor"] = v.session_score["roundsPlayedAsTraitor"] + 1
    elseif TOURNAMENT.TEAM_JESTER[v:GetRole()] then
      v.global_score["roundsPlayedAsJester"] = v.global_score["roundsPlayedAsJester"] + 1
      v.session_score["roundsPlayedAsJester"] = v.session_score["roundsPlayedAsJester"] + 1
    elseif ROLE_KILLER == v:GetRole() then
      v.global_score["roundsPlayedAsJester"] = v.global_score["roundsPlayedAsJester"] + 1
      v.session_score["roundsPlayedAsJester"] = v.session_score["roundsPlayedAsJester"] + 1
    end
  end

end

function constructScoresTableForExport()
  -- Construct the table from the JSON file

  -- We need to transfer every player's global_score table back into the TOURNAMENT.allScores
  -- all this memory juggling will get tiring maybe we should get rid of global_score and do it all
  -- in TOURNAMENT.allScores.players
  for k,v in pairs(player.getAll()) do
    TOURNAMENT.allScores.players[v:SteamID()] = v.global_score
  end

  -- We are already tracking metadata in TOURNAMENT.allScores.meta
  return TOURNAMENT.allScores -- return the table in a format that's nice for TableToJSON
end

-- Write the scores to the JSON file
function writeScoresToDisk()
  local data = util.TableToJSON(constructScoresTableForExport()) -- Convert the player table to JSON
  if not file.Exists("tournamentscoring") then
    file.CreateDir( "tournamentscoring" ) -- Create the directory if it doesn't exist
  end
  file.Write( "tournamentscoring/playerdata.json", data) -- Write the data to the JSON file
end

-- If player not in tournament table then add player to the tournament table
function addToTournament(ply)
  -- Check if that SteamID already in the allScores.players table
  if not TOURNAMENT.allScores.players[v:SteamID()] then
    -- WARNING players must have a valid global_score table before doing this. Make sure to create when
    -- joining the server.
    TOURNAMENT.allScores.players[v:SteamID()] = v:global_score
    PrintMessage(HUD_PRINTCONSOLE, "Player" .. v:Nick() .. "added to tournament scoring table.")
  end
end

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

-- Hook function for applying scores at end of round accepts win type as vararg input
function roundEndScoring(win_type)
  --readScoresFromDisk()
  
  -- *functions to hand out scores to go here*
  roundEndTeamScoring(win_type)
  --roundEndIndividualScoring() -- not implemented
  --rountEndVoteScoring()       -- not implemented

  writeScoresToDisk()
end

hook.Add("TTTEndRound", "TournamentRoundEndScoring", roundEndScoring)
