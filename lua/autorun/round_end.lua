-- Handle all the round end stuff in here, scoring plus saving

-- Calculate baseline bonus for members of winning team
function calcTeamWinBonus(wintype)

    util.ttttDebug("TTTT DEBUG: Computing win bonuses")

    local win_bonus = 0

    -- Check who won and calculate team score
    if wintype == WIN_INNOCENT or wintype == WIN_TIMELIMIT then
        -- Innocents win - bonus = number of living players remaining
        -- Yes this will give a bonus for a living jester
        util.ttttDebug("TTTT DEBUG: Innocent win computation")
        for k,v in pairs(player.GetAll()) do
            win_bonus = win_bonus + util.bool2num(v:Alive())
        end
    elseif wintype == WIN_TRAITOR then
        -- Traitors get (num_killed)/(num_traitor-num_dead_traitor)

        util.ttttDebug("TTTT DEBUG: Traitor win computation")
        num_killed = 0
        num_traitor = 0
        num_dead_traitor = 0
        -- For all players get required numbers, this should be replaced
        -- with online tracking of these values
        for k,v in pairs(player.GetAll()) do
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
                num_killed = num_killed + bool2num(v:Alive())
            end
        end

        -- Calculate win bonus
        win_bonus = num_killed/(num_traitor-num_dead_traitor)

    elseif wintype == WIN_KILLER then
        util.ttttDebug("TTTT DEBUG: Killer win computation")
        -- Killer kills everyone, bonus = 1 per kill
        win_bonus = self.round_score["innocentKills"] + self.round_score["traitorKills"]
    elseif wintype == WIN_JESTER then
        util.ttttDebug("TTTT DEBUG: Jester win computation")
        -- Jester jests everyone, bonus = 1 per player on server
        win_bonus = player.GetCount()
    end

    util.ttttDebug("TTTT DEBUG: Win bonus is" .. win_bonus)

    return win_bonus

end


-- Hand out scores at end of round for team performance
function roundEndTeamScoring(win_type)

    util.ttttDebug("TTTT DEBUG: Round end compute scoring and assign")

    -- Winning team base bonus
    local win_bonus = calcTeamWinBonus(win_type)

    -- For each player check if their team won and allocate points
    for k,v in pairs(player.GetAll()) do

        -- If player role is a valid key in the table indexed by the win
        -- condition then award the win_bonus score to that player.
        if TOURNAMENT.winComp[win_type][v:GetRole()] == true then

            -- Calculate player modifer
            local score_modifier = 1

            -- Extra modifiers go here

            -- Half points for deados is final modifier
            if v:Alive() ~= true then score_modifier = score_modifier/2 end

            util.ttttDebug("TTTT DEBUG: Score modifier for" .. v:Nick() .. score_modifier)

            ply_score = win_bonus*score_modifier

            -- Give win bonus to player
            util.ttttDebug("TTTT DEBUG: " .. v:Nick() .. " awarded " .. ply_score)
            v:PrintMessage( HUD_PRINTTALK, "You have been awarded " .. (ply_score) .. " end of round points!" )
            v:awardScore(ply_score)
        end
    end

end

function roundEndIncrementCounters()

    util.ttttDebug("TTTT DEBUG: Round end increment all counters")

    if SERVER then

    --increment overall round counters
    TOURNAMENT.allScores.meta.totalRounds = TOURNAMENT.allScores.meta.totalRounds + 1
    TOURNAMENT.sessionRounds = TOURNAMENT.sessionRounds + 1

    end

    util.ttttDebug("TTTT DEBUG: Total Rounds Ever: " .. TOURNAMENT.allScores.meta.totalRounds)
    util.ttttDebug("TTTT DEBUG: Total Rounds This Sesh: " .. TOURNAMENT.sessionRounds)

    --increment players' individual round counters, depending on which team they're on
    for k,v in pairs(player.GetAll()) do

        util.ttttDebug("TTTT DEBUG: This is player " .. v:Nick())

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
    for k,v in pairs(player.GetAll()) do
        TOURNAMENT.allScores.players[v:SteamID()] = v.global_score
    end

    -- We are already tracking metadata in TOURNAMENT.allScores.meta
    return TOURNAMENT.allScores -- return the table in a format that's nice for TableToJSON
end

-- Write the scores to the JSON file
function writeScoresToDisk()

    util.ttttDebug("TTTT DEBUG: Convert player data to JSON")
    local data = util.TableToJSON(constructScoresTableForExport()) -- Convert the player table to JSON
    
    if not file.Exists("tournamentscoring", "DATA") then
        util.ttttDebug("TTTT DEBUG: Save file not found creating directory")
        file.CreateDir( "tournamentscoring" ) -- Create the directory if it doesn't exist
    end

    util.ttttDebug("TTTT DEBUG: Write out player scores")
    file.Write( "tournamentscoring/playerdata.json", data) -- Write the data to the JSON file
end

-- Hook function for applying scores at end of round accepts win type as vararg input
function roundEndScoring(win_type)
  -- no need to read because all data already in TOURNAMENT.allScores table
  -- at server start must call readScoresFromDisk()
  --readScoresFromDisk()
  util.ttttDebug("TTTT DEBUG: Running round end scoring")
  roundEndIncrementCounters()

  -- *functions to hand out scores to go here*
  util.ttttDebug("TTTT DEBUG: Assigning team scores for round end")
  roundEndTeamScoring(win_type)
  --roundEndIndividualScoring() -- not implemented
  --rountEndVoteScoring()       -- not implemented

  util.ttttDebug("TTTT DEBUG: Write scores to disk")
  writeScoresToDisk()
end


hook.Add("TTTEndRound", "TournamentRoundEndScoring", roundEndScoring)


