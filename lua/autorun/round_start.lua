-- Handle all the round start stuff in here, resetting round scores, etc.

gameevent.Listen("TTTPrepareRound")
hook.Add("TTTPrepareRound", "TournamentRoundPrep", function()
  if SERVER then
    TOURNAMENT:allTimeScoreboard()
  end
end)

gameevent.Listen("TTTBeginRound")
hook.Add("TTTBeginRound", "TournamentRoundStart", function()
  if SERVER then
    util.ttttDebug("Round Start Initialisation")
    for k, ply in pairs(player.GetAll()) do
      ply:initRoundScoreTable()
    end
  end
end)