-- Handle all the round end stuff in here, scoring plus saving

-- Calculate baseline bonus for members of winning team
function TOURNAMENT:CalcTeamWinBonus(win_type)

    util.ttttDebug("Computing win bonuses")


    local win_bonus = 0

    -- Check who won and calculate team score
    if win_type == WIN_INNOCENT or win_type == WIN_TIMELIMIT then
        -- Innocents win - bonus = number of living players remaining
        -- Yes this will give a bonus for a living jester
        util.ttttDebug("Innocent win computation")
        for k,v in pairs(player.GetAll()) do
            win_bonus = win_bonus + util.bool2num(v:Alive())
        end
    elseif win_type == WIN_TRAITOR then
        -- Traitors get (num_killed)/(num_traitor-num_dead_traitor)

        util.ttttDebug("Traitor win computation")
        local num_killed = 0
        local num_traitor = 0
        local num_dead_traitor = 0
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
                num_killed = num_killed + util.bool2num(v:Alive())
            end
        end

        -- Calculate win bonus
        win_bonus = num_killed/(num_traitor-num_dead_traitor)

    elseif win_type == WIN_KILLER then
        util.ttttDebug("Killer win computation")
        -- Killer kills everyone, bonus = 1 per kill
        win_bonus = self.round_score["innocentKills"] + self.round_score["traitorKills"]        -- shouldn't be self? Fix.
    elseif win_type == WIN_JESTER then
        util.ttttDebug("Jester win computation")
        -- Jester jests everyone, bonus = 1 per player on server
        win_bonus = player.GetCount()
    end

    util.ttttDebug("Win bonus is " .. win_bonus)

    return win_bonus

end


-- Hand out scores at end of round for team performance
function TOURNAMENT:RoundEndTeamScoring(win_type)

    if SERVER then
        util.ttttDebug("Round end compute scoring and assign")

        -- Winning team base bonus
        local win_bonus = TOURNAMENT.CalcTeamWinBonus(win_type)
        -- For each player check if their team won and allocate points
        for k,ply in pairs(player.GetAll()) do

            -- If player role is a valid key in the table indexed by the win
            -- condition then award the win_bonus score to that player.
            if TOURNAMENT.winComp[win_type][ply:GetRole()] == true then

                -- Calculate player modifer
                local score_modifier = 1

                -- Extra modifiers go here

                -- Half points for deados is final modifier
                if ply:Alive() ~= true then score_modifier = score_modifier/2 end

                util.ttttDebug("Score modifier for " .. ply:Nick() .. ": " .. score_modifier)

                local ply_score = win_bonus*score_modifier

                -- Give win bonus to player
                util.ttttDebug(ply:Nick() .. " awarded " .. ply_score .. " end of round points")
                ply:awardScore(ply_score)
                ply:logScore(ply_score .. " end of round points")
            end
        end
    end

end

-- Increment Round Counters For Everyone and The Server
function TOURNAMENT:RoundEndIncrementCounters()

    util.ttttDebug("Round end increment all counters")

    if SERVER then

        --increment overall round counters
        TOURNAMENT.allScores.meta.totalRounds = TOURNAMENT.allScores.meta.totalRounds + 1
        TOURNAMENT.sessionRounds = TOURNAMENT.sessionRounds + 1

    end

    util.ttttDebug("Total Rounds Ever: " .. TOURNAMENT.allScores.meta.totalRounds)
    util.ttttDebug("Total Rounds This Sesh: " .. TOURNAMENT.sessionRounds)

    --increment players' individual round counters, depending on which team they're on
    for k,ply in pairs(player.GetAll()) do

        ply.global_score.roundsPlayed = ply.global_score.roundsPlayed + 1
        ply.session_score.roundsPlayed = ply.session_score.roundsPlayed + 1

        if TOURNAMENT.TEAM_INNOCENT[ply:GetRole()] then
            ply.global_score.roundsPlayedAsInnocent = ply.global_score.roundsPlayedAsInnocent + 1
            ply.session_score.roundsPlayedAsInnocent = ply.session_score.roundsPlayedAsInnocent + 1
        elseif TOURNAMENT.TEAM_TRAITOR[ply:GetRole()] then
            ply.global_score.roundsPlayedAsTraitor = ply.global_score.roundsPlayedAsTraitor + 1
            ply.session_score.roundsPlayedAsTraitor = ply.session_score.roundsPlayedAsTraitor + 1
        elseif TOURNAMENT.TEAM_JESTER[ply:GetRole()] then
            ply.global_score.roundsPlayedAsJester = ply.global_score.roundsPlayedAsJester + 1
            ply.session_score.roundsPlayedAsJester = ply.session_score.roundsPlayedAsJester + 1
        elseif ROLE_KILLER == ply:GetRole() then
            ply.global_score.roundsPlayedAsJester = ply.global_score.roundsPlayedAsJester + 1
            ply.session_score.roundsPlayedAsJester = ply.session_score.roundsPlayedAsJester + 1
        end
    end

end

function TOURNAMENT:transferRoundScoresToGlobalScores()
    if SERVER then
        util.ttttDebug("Transfer & distribute the round scores to the global tables")

        -- Loop through the table keys, and transfer them from each player to the TOURNAMENT.allScores table
        local sharedAttributres = {"totalScore", "traitorKills", "innocentKills", "killerKills", "jesterKills", "ownTeamKills", "suicides"}
        for i,ply in pairs(player.GetAll()) do
            for j,attr in pairs(sharedAttributres) do
                ply.global_score[attr] = ply.global_score[attr] + ply.round_score[attr]
                ply.session_score[attr] = ply.session_score[attr] + ply.round_score[attr]
            end

            -- Transfer weapon usage for this round
            local i = true
            local fave = ""
            for weap, kills in pairs(ply.round_score.weapons) do
                if i then
                    fave = weap
                end
                if ply.global_score.weapons[weap] ~= nil then
                    ply.global_score.weapons[weap] = ply.global_score.weapons[weap] + kills
                    if ply.global_score.weapons[weap] > ply.global_score.weapons[fave] then
                        fave = weap
                    end
                else
                    ply.global_score.weapons[weap] = kills
                end
                i = false
            end
            ply.global_score.favouriteWeapon = fave
        end
    end
end


-- Write the scores to the JSON file
function TOURNAMENT:WriteScoresToDisk()
    if SERVER then
        util.ttttDebug("Convert player data to JSON")
        -- Update TOURNAMENT.allScores with the current data stored in the player entities.
        for k,ply in pairs(player.GetAll()) do
            TOURNAMENT.allScores.players[ply:SteamID()] = ply.global_score
        end

        -- Convert the player table to JSON
        local JSONdata = util.TableToJSON(TOURNAMENT.allScores)

        if not file.Exists("tournamentscoring", "DATA") then
            util.ttttDebug("Save file not found creating directory")
            file.CreateDir( "tournamentscoring" ) -- Create the directory if it doesn't exist
        end

        util.ttttDebug("Write out player scores")
        file.Write( "tournamentscoring/playerdata.json", JSONdata) -- Write the data to the JSON file
    end
end

gameevent.Listen("TTTEndRound")
hook.Add("TTTEndRound", "TournamentRoundEndScoring", function(win_type)

    -- no need to read because all data already in TOURNAMENT.allScores table
    -- at server start must call readScoresFromDisk()
    --readScoresFromDisk()
    if SERVER and TOURNAMENT.FirstInit then
        util.ttttDebug("Running round end scoring")
        TOURNAMENT:RoundEndIncrementCounters()

        -- *functions to hand out scores to go here*
        util.ttttDebug("Assigning team scores for round end")
        TOURNAMENT:RoundEndTeamScoring(win_type)
        TOURNAMENT:transferRoundScoresToGlobalScores()

        --roundEndIndividualScoring() -- not implemented
        --rountEndVoteScoring()       -- not implemented  

        -- Tell everyone their score
        for k,ply in pairs(player.GetAll()) do
            ply:reportRoundScore()
        end

        util.ttttDebug("Write scores to disk")

        TOURNAMENT.WriteScoresToDisk()
    end

end)