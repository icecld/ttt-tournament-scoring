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

-- Generate and send a full scoreboard to each online player.
function TOURNAMENT.AnnouncePoints()
    for i, ply in ipairs( player.GetAll() ) do
        for i, ply2 in ipairs( player.GetAll() ) do
            ply:PrintMessage( HUD_PRINTTALK, ply2:GetName() .. ": " .. ply2.global_score.totalScore .. ", " .. ply2.global_score.roundsPlayed .. " rounds")
        end
	end
end

-- Table for storing all-time data
function plymeta:initGlobalScoreTable()
    util.ttttDebug("Initialise player global_score table for" .. self:Name())
    self.global_score = {}
    self.global_score.nick = self:GetName()
    self.global_score.roundsPlayed = 0
    self.global_score.roundsPlayedAsInnocent = 0
    self.global_score.roundsPlayedAsTraitor = 0
    self.global_score.roundsPlayedAsJester = 0
    self.global_score.roundsPlayedAsKiller = 0

    -- shared attributes
    self.global_score.totalScore = 0
    self.global_score.traitorKills = 0
    self.global_score.innocentKills = 0
    self.global_score.killerKills = 0
    self.global_score.jesterKills = 0
    self.global_score.ownTeamKills = 0
    self.global_score.suicides = 0

    self.global_score.weapons = {}
    self.global_score.favouriteWeapon = ""
end

-- Table for storing session data
function plymeta:initSessionScoreTable()
    util.ttttDebug("Initialise player session_score table for ".. self:Name())
    self.session_score = {}
    self.session_score.roundsPlayed = 0
    self.session_score.roundsPlayedAsInnocent = 0
    self.session_score.roundsPlayedAsTraitor = 0
    self.session_score.roundsPlayedAsJester = 0
    self.session_score.roundsPlayedAsKiller = 0


    self.session_score.totalScore = 0
    self.session_score.traitorKills = 0
    self.session_score.innocentKills = 0
    self.session_score.killerKills = 0
    self.session_score.jesterKills = 0
    self.session_score.ownTeamKills = 0
    self.session_score.suicides = 0

    self.session_score.weapons = {}

end

--Table for storing round data
function plymeta:initRoundScoreTable()
    util.ttttDebug("Initialise player round_score table for " .. self:Name())
    self.round_score = {}
    self.round_score.log = {}


    self.round_score.totalScore = 0
    self.round_score.traitorKills = 0
    self.round_score.innocentKills = 0
    self.round_score.killerKills = 0
    self.round_score.jesterKills = 0
    self.round_score.ownTeamKills = 0
    self.round_score.suicides = 0
    self.round_score.totalKills = 0

    self.round_score.weapons = {}

end

-- Increment round_score Traitor Kill Counter
function plymeta:incTraitorKills()
    self.round_score.traitorKills = self.round_score.traitorKills + 1
end

-- Increment round_score Innocent Kill Counter
function plymeta:incInnocentKills()
    self.round_score.innocentKills = self.round_score.innocentKills + 1
end

-- Increment round_score Killer Kill Counter
function plymeta:incKillerKills()
    self.round_score.killerKills = self.round_score.killerKills + 1
end

-- Increment round_score Jester Kill Counter
function plymeta:incJesterKills()
    self.round_score.jesterKills = self.round_score.jesterKills + 1
end

-- Increment round_score Own Team Kill Counter
function plymeta:incOwnTeamKills()
    self.round_score.jesterKills = self.round_score.jesterKills + 1
end

-- Increment round_score Suicides Counter
function plymeta:incSuicides()
    self.round_score.jesterKills = self.round_score.jesterKills + 1
end

-- Increment round_score Kill Counter by supplied role
function plymeta:incKillCountersByRole(role)
    if      TOURNAMENT.TEAM_TRAITOR[role] then
        self:incTraitorKills()
    elseif  TOURNAMENT.TEAM_INNOCENT[role] then
        self:incInnocentKills()
    elseif  TOURNAMENT.TEAM_JESTER[role] then
        self:incJesterKills()
    elseif  role == ROLE_KILLER then
        self:incKillerKills()
    end
end

-- Save to a message to a log that will be sent to the player at the end of the round
-- (to prevent people knowing information they shouldn't know before the end of the round)
function plymeta:logScore(msg)
    util.ttttDebug("SCORE LOG: " .. self:GetName() .. ": " .. msg)
    table.insert(self.round_score.log, msg)
end

-- Tell the player their all time score
function plymeta:printScore()
    self:PrintMessage( HUD_PRINTTALK, "Your all-time score is " .. self.global_score.totalScore .. ", over " .. self.global_score.roundsPlayed .. " rounds.")
end

-- Tell the player what their score is, and how it changed that round.
function plymeta:reportRoundScore()
    for i, msg in ipairs(self.round_score.log) do
        self:PrintMessage( HUD_PRINTTALK, msg)
    end
    self:printScore()
end

-- Award player some score
function plymeta:awardScore(pnts)
    -- We only need to do the round score, session and global
    -- are updated at the end of the round
    self.round_score.totalScore = self.round_score.totalScore + pnts
end

-- Penalise player some points
function plymeta:nerfScore(pnts)
    -- We only need to do the round score, session and global
    -- are updated at the end of the round
    self.round_score.totalScore = self.round_score.totalScore - pnts
end

function plymeta:funfact()
    local facts = {
        [0] = ("You've played " .. self.global_score.roundsPlayed .. " round" .. util.ttttPluralise(self.global_score.roundsPlayed) .."!"),
        [1] = ("You've killed " .. self.global_score.traitorKills .. " traitor" .. util.ttttPluralise(self.global_score.traitorKills) .."!"),
        [2] = ("You've killed " .. self.global_score.innocentKills .. " innocent" .. util.ttttPluralise(self.global_score.innocentKills) .."!"),
        [3] = ("You've killed " .. self.global_score.killerKills.. " killer" .. util.ttttPluralise(self.global_score.killerKills) .."!"),
        [4] = ("You've killed " .. self.global_score.jesterKills.. " jesters or swapper" .. util.ttttPluralise(self.global_score.jesterKills) .."!"),
        [5] = ("You've have " .. self.global_score.ownTeamKills.. " own team kill" .. util.ttttPluralise(self.global_score.ownTeamKills) .."!"),
        [6] = ("You've commited suicide " .. self.global_score.suicides .. " time" .. util.ttttPluralise(self.global_score.suicides) .."!"),
    }
    return facts[math.random(0, 6)]
end