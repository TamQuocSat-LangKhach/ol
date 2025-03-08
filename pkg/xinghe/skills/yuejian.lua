local yuejian = fk.CreateSkill{
  name = "ol__yuejian",
}

Fk:loadTranslationTable{
  ["ol__yuejian"] = "约俭",
  [":ol__yuejian"] = "每回合限两次，当其他角色对你使用的牌结算完毕置入弃牌堆时，你可以展示所有手牌，若花色与此牌均不同，你获得之。",

  ["#ol__yuejian-invoke"] = "约俭：你可以展示所有手牌，若花色均与%arg不同，你获得之",

  ["$ol__yuejian1"] = "无文绣珠玉，器皆黑漆。",
  ["$ol__yuejian2"] = "性情约俭，不尚华丽。",
}

yuejian:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuejian.name) and target ~= player and
      not player:isKongcheng() and table.contains(data.tos, player) and
      player.room:getCardArea(data.card) == Card.Processing and
      player:usedSkillTimes(yuejian.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yuejian.name,
      prompt = "#ol__yuejian-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local yes = table.every(player:getCardIds("h"), function (id)
      return data.card:compareSuitWith(Fk:getCardById(id), true)
    end)
    player:showCards(player:getCardIds("h"))
    if player.dead or room:getCardArea(data.card) ~= Card.Processing then return end
    if yes then
      room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, yuejian.name)
    end
  end,
})

return yuejian
