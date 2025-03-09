local kanpo = fk.CreateSkill{
  name = "ol_ex__kanpo",
}

Fk:loadTranslationTable {
  ["ol_ex__kanpo"] = "看破",
  [":ol_ex__kanpo"] = "你可以将一张黑色牌当【无懈可击】使用。你使用的【无懈可击】不能被响应。",

  ["#ol_ex__kanpo-viewas"] = "看破：你可以将一张黑色牌当【无懈可击】使用",

  ["$ol_ex__kanpo1"] = "此计奥妙，我已看破。",
  ["$ol_ex__kanpo2"] = "还有什么是我看不破的？",
}

kanpo:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#ol_ex__kanpo",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = kanpo.name
    card:addSubcard(cards[1])
    return card
  end,
})

kanpo:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(kanpo.name) and data.card.trueName == "nullification"
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = player.room.alive_players
  end,
})

return kanpo