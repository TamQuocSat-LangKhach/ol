local this = fk.CreateSkill { name = "ol_ex__hongyan", }

this:addEffect("filter", {
  frequency = Skill.Compulsory,
  card_filter = function(self, to_select, player, isJudgeEvent)
    return to_select.suit == Card.Spade and player:hasSkill(this.name) and
    (table.contains(player:getCardIds("he"), to_select.id) or isJudgeEvent)
  end,
  view_as = function (self, player, card)
    return Fk:cloneCard(card.name, Card.Heart, card.number)
  end,
})

this:addEffect("maxcards", {
  fixed_func = function (self, player)
    if player:hasSkill(this.name) and #table.filter(player:getCardIds(Player.Equip), function (id) return Fk:getCardById(id).suit == Card.Heart end) > 0  then
      return player.maxHp
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__hongyan"] = "红颜",
  [":ol_ex__hongyan"] = "锁定技，①你的♠牌或你的♠判定牌的花色视为<font color='red'>♥</font>。"..
  "②若你的装备区里有<font color='red'>♥</font>牌，你的手牌上限初值改为体力上限。",

  ["$ol_ex__hongyan1"] = "红颜娇花好，折花门前盼。",
  ["$ol_ex__hongyan2"] = "我的容貌，让你心动了吗？",
}

return this
