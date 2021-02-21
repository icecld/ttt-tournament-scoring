-- Hooks & Routines for awarding imdividual scores for
-- player activities during the round go in this file.

--
    BaseScore = 10               -- Set a base score to be used (don't know the best value yet)
    BoringWeapons = {"weapon_ttt_m16", "weapon_ttt_unarmed", "weapon_zm_shotgun", "weapon_ttt_push", "weapon_zm_pistol", "weapon_zm_rifle", "weapon_ttt_glock", "weapon_zm_mac10", "weapon_zm_revolver"}
    -- Set a list of boring weapons that we don't give bonus points for kills with
    ProblematicWeapons = {"npc_barnacle", "ttt_banana_proj", "ttt_frag_proj", "prop_physics", "nv_explosion"}

    -- Body found (encourage searching bodies)
    gameevent.Listen("TTTBodyFound")
    hook.Add("TTTBodyFound", "BodyFound", function(ply, deadply, rag)
        ply:awardScore(BaseScore)
        ply:logScore((BaseScore) .. " points for serching a body" )
    end)

    -- Bought an item (encourage buying items)
    gameevent.Listen("TTTOrderedEquipment")
    hook.Add("TTTOrderedEquipment", "OrderedEquimpment", function(ply, equipment, is_item)
        ply:awardScore(BaseScore)
        ply:logScore((BaseScore) .. " points for buying equipment" )
    end)

    -- Piggybacking on karma system (discourage bad behaviour)
    gameevent.Listen("TTTKarmaGivePenalty")
    hook.Add("TTTKarmaGivePenalty", "Karma", function(ply, penalty, victim)
        ply:logKarma(penalty)
    end)

    -- Player dies, calculate scores to give to the attackers and victims.
    gameevent.Listen("DoPlayerDeath")
    hook.Add("DoPlayerDeath", "PlayerDeath", function(victim, attacker, dmginfo)
        local inflictor = dmginfo:GetInflictor()
        if inflictor:IsValid() then
            if not util.strInTable(ProblematicWeapons, inflictor:GetClass()) then
                if dmginfo:GetAttacker():IsPlayer() then --  and not inflictor:IsValid()
                    if dmginfo:GetAttacker():Alive() then
                        inflictor = dmginfo:GetAttacker():GetActiveWeapon()
                    end
                end
            end
        end

        victim:incDeaths()
        if attacker:IsPlayer() and not attacker:IsWorld() and not (attacker == victim) then
            if TOURNAMENT.TEAM_TRAITOR[victim:GetRole()] and TOURNAMENT.TEAM_INNOCENT[attacker:GetRole()] then
                -- Victim is a traitor, attacker is innocent]

                -- Dock points from victim
                victim:awardScore(BaseScore * -1)
                victim:logScore((BaseScore * -1) .. " bonus points for letting the innocents kill you" )

                -- Award points to attacker
                attacker:awardScore(BaseScore * 1)
                attacker:logScore((BaseScore * 1) .. " bonus points for killing a traitor" )

                -- Award spree points if it's not the first kill
                if attacker.round_score.traitorKills > 0 then
                    attacker:awardScore(BaseScore * 0.5)
                    attacker:logScore((BaseScore * 0.5) .. " bonus points for a killing spree" )
                end

                -- Increment round kill counter for the innocent
                attacker:incTraitorKills()

                -- If it's the golden deagle, award a bonus
                if inflictor:GetClass() == "weapon_ttt_powerdeagle" then
                    attacker:awardScore(BaseScore * 1)
                    attacker:logScore((BaseScore * 1) .. " bonus points for good detective work" )
                end
                
                print(inflictor:GetClass() .. ' vs ' .. attacker.global_score.favouriteWeapon)
                if inflictor:IsWeapon() then
                    -- If it's an interesting weapon, award a bonus
                    if not util.strInTable(BoringWeapons, inflictor:GetClass()) then
                        attacker:awardScore(BaseScore * 1)
                        attacker:logScore((BaseScore * 1) .. " bonus points for a kill using an interesting weapon")
                    end
                    -- If it's a favourite weapon, dock points
                    if inflictor:GetClass() == attacker.global_score.favouriteWeapon then
                        attacker:awardScore(BaseScore * -0.2)
                        attacker:logScore((BaseScore * 0.2) .. " points deducted for a kill using your favourite weapon")
                    end
                end


            elseif TOURNAMENT.TEAM_INNOCENT[victim:GetRole()] and TOURNAMENT.TEAM_TRAITOR[attacker:GetRole()] then
                -- Victim is innocent, attacker is a traitor

                -- Dock points from victim
                victim:awardScore(BaseScore * -1)
                victim:logScore((BaseScore * 1) .. " points deducted for dying at the hands of a traitor" )

                -- Award points to attacker
                attacker:awardScore(BaseScore * 1.5)
                attacker:logScore((BaseScore * 1.5) .. " bonus points for killing an innocent" )

                -- Award spree points if it's not the first kill
                if attacker.round_score.innocentKills > 0 then
                    attacker:awardScore(BaseScore * 0.5)
                    attacker:logScore((BaseScore * 0.5) .. " bonus points for a killing spree" )
                end

                -- Increment round kill counter for the traitor
                attacker:incInnocentKills()
                --print("call")
                --print(inflictor)
                -- If it's an interesting weapon award a bonus
                --print(inflictor:GetClass() .. ' vs ' .. attacker.global_score.favouriteWeapon)
                if inflictor:IsWeapon() then
                    -- If it's an interesting weapon, award a bonus
                    if not util.strInTable(BoringWeapons, inflictor:GetClass()) then
                        attacker:awardScore(BaseScore * 1)
                        attacker:logScore((BaseScore * 1) .. " bonus points for a kill using an interesting weapon")
                    end
                    -- If it's a favourite weapon, dock points
                    if inflictor:GetClass() == attacker.global_score.favouriteWeapon then
                        attacker:awardScore(BaseScore * -0.2)
                        attacker:logScore((BaseScore * 0.2) .. " points deducted for a kill using your favourite weapon")
                    end
                end


            elseif TOURNAMENT.TEAM_TRAITOR[victim:GetRole()] and TOURNAMENT.TEAM_TRAITOR[attacker:GetRole()] then
                -- Victim is a traitor, attacker is also a traitor

                -- Increment round kill counter for the traitor, and own team kills counter
                attacker:incTraitorKills()
                attacker:incOwnTeamKills()

                -- Dock points for team kill
                attacker:awardScore(BaseScore * -2)
                attacker:logScore((BaseScore * 2) .. " points deducted for being an idiot and killing your team mate" )


            elseif TOURNAMENT.TEAM_INNOCENT[victim:GetRole()] and TOURNAMENT.TEAM_INNOCENT[attacker:GetRole()] then
                -- Victim is a innocent, attacker is also innocent

                -- Dock points for team kill
                attacker:awardScore(BaseScore * -2)
                attacker:logScore((BaseScore * 2) .. " points deducted for being an idiot and killing your team mate" )

                -- Increment round kill counter for the innocent, and own team kills counter
                attacker:incInnocentKills()
                attacker:incOwnTeamKills()

            elseif victim:GetRole() == ROLE_KILLER then
                -- Victim is a killer, attacker is anything else

                -- Award points to attacker
                attacker:awardScore(BaseScore * 2)
                attacker:logScore((BaseScore * 2) .. " bonus points for killing the killer" )

                -- Dock points from victim
                victim:awardScore(BaseScore * -1)
                victim:logScore((BaseScore * 1) .. " points deducted for getting killed as the killer" )

                -- Increment round kill counter for the attacker
                attacker:incKillerKills()

            elseif (attacker:GetRole() == ROLE_KILLER) and not TOURNAMENT.TEAM_JESTER[victim:GetRole()] then
                -- Attacker is a killer, victim is anything else, except team jester

                -- Award points to the killer
                attacker:awardScore(BaseScore * 1)
                attacker:logScore((BaseScore * 1) .. " bonus points for going off killing again" )

                -- Dock points from the victim
                victim:awardScore(BaseScore * -1)
                victim:logScore((BaseScore * 1) .. " points deducted for getting killed by the killer" )

                -- Increment round kill counter for the killer
                attacker:incKillCountersByRole(victim:GetRole())

            elseif TOURNAMENT.TEAM_JESTER[victim:GetRole()] then
                -- Victim is a jester or a swapper

                local jesterType = "jester"
                if victim:GetRole() == ROLE_SWAPPER then jesterType = "Swapper"

                -- Increment round kill counter for the attacker
                attacker:incJesterKills()

                -- Dock points from the attacker
                attacker:awardScore(BaseScore * -1)
                attacker:logScore((BaseScore * -1) .. " points deducted for being made a fool of by the " .. jesterType)

                -- Award points to the jester
                victim:awardScore(BaseScore * 1)
                victim:logScore((BaseScore * 1) .. " bonus points for making a fool of " .. attacker:Nick())
                end
            end
        else
            -- victim suicided in some way, or got killed by the world.
            if dmginfo:GetDamageType() == DMG_FALL then
                victim:awardScore(BaseScore * -0.5)
                victim:logScore((BaseScore * -0.5) .. " points deducted for death by fall damage")
                victim:incSuicides()
                victim:incFallDeaths()
            else
                victim:awardScore(BaseScore * -0.5)
                victim:logScore((BaseScore * -0.5) .. " points deducted for suicide or world kill")
                victim:incSuicides()
            end
        end -- weapon_ttt_unarmed
        if inflictor:IsValid() and attacker:IsPlayer() and not inflictor:IsPlayer() then
            if attacker.round_score.weapons[inflictor:GetClass()] ~= nil then
                attacker.round_score.weapons[inflictor:GetClass()] = attacker.round_score.weapons[inflictor:GetClass()] + 1
            else
                attacker.round_score.weapons[inflictor:GetClass()] = 1
            end
        end
    end)