local xiying = fk.CreateSkill{
  name = "xiying",
}

Fk:loadTranslationTable{
  ["xiying"] = "袭营",
  [":xiying"] = "出牌阶段开始时，你可以弃置一张非基本手牌，令所有其他角色选择一项：1.弃置一张牌；2.本回合不能使用或打出牌。"..
  "若如此做，结束阶段，若你于本回合出牌阶段造成过伤害，你获得牌堆中一张【杀】或伤害锦囊牌。",

  ["#xiying-invoke"] = "袭营：你可以弃置一张非基本手牌，所有其他角色需弃置一张牌，否则其本回合不能使用或打出牌",
  ["#xiying-discard"] = "袭营：你需弃置一张牌，否则本回合不能使用或打出牌",
  ["@@xiying-turn"] = "被袭营",

  ["$xiying1"] = "速袭曹营，以解乌巢之难！",
  ["$xiying2"] = "此番若功不能成，我军恐难以再战。",
}

xiying:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if player.phase == Player.Play then
        return player:hasSkill(xiying.name) and not player:isKongcheng()
      elseif player.phase == Player.Finish then
        if not player.dead and player:usedSkillTimes(xiying.name, Player.HistoryTurn) > 0 then
          local dat = {}
          player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
            if e.data.phase == Player.Play and e.end_id then
              table.insert(dat, {e.id, e.end_id})
            end
          end, Player.HistoryTurn)
          if #dat == 0 then return end
          return #player.room.logic:getActualDamageEvents(1, function (e)
            return e.data.from == player and
              table.find(dat, function (info)
                return e.id > info[1] and e.id < info[2]
              end) ~= nil
          end, Player.HistoryTurn) > 0
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if player.phase == Player.Play then
      local room = player.room
      local card = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = xiying.name,
        cancelable = true,
        pattern = ".|.|.|hand|.|^basic",
        prompt = "#xiying-invoke",
        skip = true,
      })
      if #card > 0 then
        event:setCostData(self, {tos = room:getOtherPlayers(player, false), cards = card})
        return true
      end
    else
      event:setCostData(self, nil)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Play then
      room:throwCard(event:getCostData(self).cards, xiying.name, player, player)
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not p.dead then
          if p:isNude() or
            #room:askToDiscard(p, {
              min_num = 1,
              max_num = 1,
              include_equip = true,
              skill_name = xiying.name,
              cancelable = true,
              prompt = "#xiying-discard",
            }) == 0 then
            room:setPlayerMark(p, "@@xiying-turn", 1)
          end
        end
      end
    else
      local cards = table.filter(room.draw_pile, function (id)
        return Fk:getCardById(id).is_damage_card
      end)
      if #cards > 0 then
        room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonJustMove, xiying.name, nil, false, player)
      end
    end
  end,
})
xiying:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("@@xiying-turn") > 0
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@@xiying-turn") > 0
  end,
})

return xiying
