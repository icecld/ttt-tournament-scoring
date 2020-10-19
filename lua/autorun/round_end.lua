-- Handle all the round end stuff in here, scoring plus saving

-- Table for tracking what win conditions mean for
-- different roles in the game
local TOURNAMENT.winComp = {
    [WIN_INNOCENT] = {
        [ROLE_INNOCENT] = true,
        [ROLE_DETECTIVE] = true,
        [ROLE_MERCENARY] = true,
        [ROLE_PHANTOM] = true,
        [ROLE_GLITCH] = true
    },
    [WIN_TERROR] = {
        [ROLE_TERROR] = true,
        [ROLE_VAMPIRE] = true,
        [ROLE_HYPNOTIST] = true,
        [ROLE_ZOMBIE] = true,
        [ROLE_ASSASSIN] = true
    },
    [WIN_JESTER] = {
        [ROLE_JESTER] = true,
        [ROLE_SWAPPER] = true
    },
    [WIN_KILLER] = {
        [ROLE_KILLER] = true
    },
    [WIN_TIMELIMIT] = {
        [ROLE_INNOCENT] = true,
        [ROLE_DETECTIVE] = true,
        [ROLE_MERCENARY] = true,
        [ROLE_PHANTOM] = true,
        [ROLE_GLITCH] = true
    },
}


-- Calculate baseline bonus for members of winning team
function calcTeamWinBonus(win_type)

    local win_bonus = 0
    
    -- Check who won and calculate team score 
    if wintype == WIN_INNOCENT or wintype == WIN_TIMELIMIT then
        
    else wintype == WIN_TERROR then

    else wintype == WIN_KILLER then
        -- Killer kills everyone, bonus = 1 per kill
        win_bonus = self.round_score["innocentKills"] + self.round_score["traitorKills"]
    else wintype == WIN_JESTER then
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
            
            -- Give win bonus to player
            v:awardScore(win_bonus)
        end

    end

end