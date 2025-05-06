local gaobian = fk.CreateSkill{
  name = "gaobian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["gaobian"] = "告变",
  [":gaobian"] = "锁定技，其他角色回合结束时，若本回合仅有一名角色受到过伤害，你令此受伤角色使用本回合进入弃牌堆的一张【杀】或失去1点体力。",

  ["#gaobian-use"] = "告变：使用其中一张【杀】，或点“取消”失去1点体力",

  ["$gaobian1"] = "帝髦诏甲士带兵，欲图不轨!",
  ["$gaobian2"] = "晋公何在？君上欲谋反作乱！",
}

gaobian:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(gaobian.name) and target ~= player then
      local to, yes = nil, true
      player.room.logic:getActualDamageEvents(1, function (e)
        if to == nil then
          to = e.data.to
        elseif to ~= e.data.to then
          yes = false
        end
      end, Player.HistoryTurn)
      if yes and to and not to.dead then
        event:setCostData(self, {tos = {to}})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).trueName == "slash" and table.contains(player.room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    local to = event:getCostData(self).tos[1]
    if #cards == 0 or not room:askToUseRealCard(to, {
      pattern = cards,
      skill_name = gaobian.name,
      prompt = "#gaobian-use",
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = cards,
      }
    }) then
      room:loseHp(to, 1, gaobian.name)
    end
  end,
})

return gaobian
