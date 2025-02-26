local hongyan = fk.CreateSkill {
  name = "ol_ex__hongyan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ol_ex__hongyan"] = "红颜",
  [":ol_ex__hongyan"] = "锁定技，你的♠牌或你的♠判定牌的花色视为<font color='red'>♥</font>。"..
  "若你的装备区里有<font color='red'>♥</font>牌，你的手牌上限改为体力上限。",

  ["$ol_ex__hongyan1"] = "红颜娇花好，折花门前盼。",
  ["$ol_ex__hongyan2"] = "我的容貌，让你心动了吗？",
}

hongyan:addEffect("filter", {
  card_filter = function(self, to_select, player, isJudgeEvent)
    return to_select.suit == Card.Spade and player:hasSkill(hongyan.name) and
      (table.contains(player:getCardIds("he"), to_select.id) or isJudgeEvent)
  end,
  view_as = function (self, player, card)
    return Fk:cloneCard(card.name, Card.Heart, card.number)
  end,
})

hongyan:addEffect("maxcards", {
  fixed_func = function (self, player)
    if player:hasSkill(hongyan.name) and table.find(player:getCardIds("e"), function (id)
      return Fk:getCardById(id).suit == Card.Heart
    end) then
      return player.maxHp
    end
  end,
})

return hongyan
