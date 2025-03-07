local qianya = fk.CreateSkill{
  name = "qianya",
}

Fk:loadTranslationTable{
  ["qianya"] = "谦雅",
  [":qianya"] = "当你成为锦囊牌的目标后，你可以将任意张手牌交给一名其他角色。",

  ["#qianya-give"] = "谦雅：你可以将任意张手牌交给一名其他角色",

  ["$qianya1"] = "君子不妄动，动必有道。",
  ["$qianya2"] = "哎！将军过誉了！",
}

qianya:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qianya.name) and
      data.card.type == Card.TypeTrick and not player:isKongcheng() and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 999,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = qianya.name,
      prompt = "#qianya-give",
      cancelable = true,
    })
    if #tos > 0 and #cards > 0 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, qianya.name, nil, true, player)
  end,
})

return qianya
