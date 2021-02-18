-- Handle all the round start stuff in here, resetting round scores, etc.


gameevent.Listen("TTTBeginRound")
hook.Add("TTTBeginRound", "RoundStart", function()
  if SERVER then
    util.ttttDebug("Round Start Initialisation")
    for k, ply in pairs(player.GetAll()) do
      ply:initRoundScoreTable()
    end
  end
end)