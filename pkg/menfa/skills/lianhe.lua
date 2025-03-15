local lianhe = fk.CreateSkill{
  name = "lianhe",
}

Fk:loadTranslationTable{
  ["lianhe"] = "连和",
  [":lianhe"] = "出牌阶段开始时，你可以横置两名角色，这些角色的下个出牌阶段结束时，若其于此阶段内未摸过牌，其选择："..
  "1.令你摸X+1张牌；2.交给你X-1张牌（X为其于此阶段内得到过的牌数且至多为3）。",

  ["#lianhe-choose"] = "连和：横置两名角色，你根据其下个出牌阶段获得牌数摸牌",
  ["@@lianhe"] = "连和",
  ["@@lianhe-phase"] = "连和",
  ["#lianhe-card"] = "连和：你需交给 %src %arg张牌，否则其摸%arg2张牌",

  ["$lianhe1"] = "枯草难存于劲风，唯抱簇得生。",
  ["$lianhe2"] = "吾所来之由，一为好，二为和。",
}

lianhe:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianhe.name) and player.phase == Player.Play and
      #table.filter(player.room.alive_players, function(p)
        return not p.chained
      end) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p.chained
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 2,
      max_num = 2,
      targets = targets,
      skill_name = lianhe.name,
      prompt = "#lianhe-choose",
      cancelable = true,
    })
    if #tos == 2 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    for _, p in ipairs(tos) do
      if not p.dead then
        p:setChainState(true)
        room:addTableMarkIfNeed(p, "@@lianhe", player.id)
      end
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("@@lianhe") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@lianhe-phase", player:getMark("@@lianhe"))
    room:setPlayerMark(player, "@@lianhe", 0)
  end,
})
lianhe:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return not player.dead and target.phase == Player.Play and
      table.contains(target:getTableMark("@@lianhe-phase"), player.id) and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.to == target and move.moveReason == fk.ReasonDraw then
            return true
          end
        end
      end, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = 0
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.to == target and move.toArea == Card.PlayerHand then
          n = n + #move.moveInfo
        end
      end
      return n > 2
    end, Player.HistoryPhase)
    n = math.min(n, 3)
    if n < 2 or target == player then
      player:drawCards(n + 1, lianhe.name)
    else
      local cards = room:askToCards(target, {
        min_num = n - 1,
        max_num = n - 1,
        include_equip = true,
        skill_name = lianhe.name,
        prompt = "#lianhe-card:"..player.id.."::"..tostring(n - 1)..":"..tostring(n + 1),
        cancelable = true,
      })
      if #cards == n - 1 then
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, lianhe.name, nil, false, target)
      else
        player:drawCards(n + 1, lianhe.name)
      end
    end
  end,
})

return lianhe
