local this = fk.CreateSkill{
  name = "ol_ex__kanpo",
}

this:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#ol_ex__kanpo-viewas",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = this.name
    card:addSubcard(cards[1])
    return card
  end,
})

this:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and data.card.trueName == "nullification"
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__kanpo"] = "看破",
  [":ol_ex__kanpo"] = "①你可以将一张黑色牌转化为【无懈可击】使用。②你使用的【无懈可击】不能被响应。",

  ["#ol_ex__kanpo-viewas"] = "发动看破，选择一张黑色牌转化为【无懈可击】使用",

  ["$ol_ex__kanpo1"] = "此计奥妙，我已看破。",
  ["$ol_ex__kanpo2"] = "还有什么是我看不破的？",
}

return this