local yishi = fk.CreateSkill{
  name = "yishi",
}

Fk:loadTranslationTable{
  ["yishi"] = "宜室",
  [":yishi"] = "每回合限一次，当一名其他角色于其出牌阶段弃置手牌后，你可以令其获得其中的一张牌，然后你获得其余的牌。",

  ["#yishi-invoke"] = "宜室：你可以令 %dest 收回一张弃置的牌，你获得其余的牌",
  ["#yishi-ask"] = "宜室：选择 %dest 收回的一张牌，你获得其余的牌",

  ["$yishi1"] = "家庭和顺，夫妻和睦。",
  ["$yishi2"] = "之子于归，宜其室家。",
}

yishi:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yishi.name) and player:usedSkillTimes(yishi.name, Player.HistoryTurn) == 0 then
      local room = player.room
      local to, cards = nil, {}
      for _, move in ipairs(data) do
        if move.from and move.from ~= player and move.moveReason == fk.ReasonDiscard and
          move.from.phase == Player.Play and not move.from.dead then
          to = move.from
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      if #cards > 0 then
        event:setCostData(self, {cards = cards, tos = {to}})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yishi.name,
      prompt = "#yishi-invoke::"..event:getCostData(self).tos[1].id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards
    local give = cards[1]
    if #cards > 1 then
      give = room:askToChooseCard(player, {
        target = to,
        flag = { card_data = {{ "yishi", cards }} },
        skill_name = yishi.name,
        prompt = "#yishi-ask::"..to.id,
      })
    end
    room:moveCardTo(give, Player.Hand, to, fk.ReasonJustMove, yishi.name, nil, true, to)
    if player.dead then return end
    cards = table.filter(cards, function (id)
      return id ~= give and table.contains(room.discard_pile, id)
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, yishi.name, nil, true, player)
    end
  end,
})

return yishi
