-- Serverside extensions to the player metatable

-- Following ttt grab metatable for players
local plymeta = FindMetaTable( "Player" )
if not plymeta then Error("FAILED TO FIND PLAYER TABLE") return end



-- Defining player tournament scoring table JSON
-- "{
--			"steamID": "Steam ID string",
--			"roundsPlayed": 0,
--			"roundsPlayedAsInnocent": 0,
--			"roundsPlayedAsTraitor": 0,
--			"roundsPlayedAsJester": 0,
--			"roundsPlayedAsKiller": 0,
--			"totalScore": 0,
--			"traitorKills": 0,
--			"innocentKills": 0,
--			"killerKills": 0,
--			"jesterKills": 0,
--			"ownTeamKills": 0
--		}

function plymeta:initGlobalScoreTable()

  self.global_score = {}
  self.global_score["roundsPlayed"] = 0
  self.global_score["roundsPlayedAsInnocent"] = 0
  self.global_score["roundsPlayedAsTraitor"] = 0
  self.global_score["roundsPlayedAsJester"] = 0
  self.global_score["roundsPlayedAsKiller"] = 0
  self.global_score["totalScore"] = 0
  self.global_score["traitorKills"] = 0
  self.global_score["innocentKills"] = 0
  self.global_score["killerKills"] = 0
  self.global_score["jesterKills"] = 0
  self.global_score["ownTeamKills"] = 0

end

-- Table for storing session data
function plymeta:initSessionScoreTable()

    self.session_score = {}
    self.session_score["roundsPlayed"] = 0
    self.session_score["roundsPlayedAsInnocent"] = 0
    self.session_score["roundsPlayedAsTraitor"] = 0
    self.session_score["roundsPlayedAsJester"] = 0
    self.session_score["roundsPlayedAsKiller"] = 0
    self.session_score["totalScore"] = 0
    self.session_score["traitorKills"] = 0
    self.session_score["innocentKills"] = 0
    self.session_score["killerKills"] = 0
    self.session_score["jesterKills"] = 0
    self.session_score["ownTeamKills"] = 0

end

--Table for storing round data
function plymeta:initRoundScoreTable()

    self.round_score = {}
    self.round_score["score"] = 0
    self.round_score["traitorKills"] = 0
    self.round_score["innocentKills"] = 0
    self.round_score["killerKills"] = 0
    self.round_score["jesterKills"] = 0

end

-- Print player's current global score
function plymeta:printScore()
    self:PrintMessage( HUD_PRINTTALK, "Your all-time score is " .. self.global_score["totalScore"] .. ", over " .. self.global_score["totalRounds"] .. " rounds.")
end

-- Award player some score
function plymeta:awardScore(pnts)
    -- We only need to do the round score, session and global
    -- are updated at the end of the round
    self.round_score["score"] = self.round_score["score"] + pnts
end

-- Penalise player some points
function plymeta:nerfScore(pnts)
    -- We only need to do the round score, session and global
    -- are updated at the end of the round
    self.round_score["score"] = self.round_score["score"] - pnts
end
