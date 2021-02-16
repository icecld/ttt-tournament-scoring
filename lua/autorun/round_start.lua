-- Handle all the round start stuff in here, resetting round scores, etc.

function roundStart()
    for k, ply in pairs(player.GetAll()) do
		ply:initRoundScoreTable()
    end
end

hook.Add("TTTPrepareRound", "RoundStart", roundStart)