local wushen = fk.CreateSkill{
  name = "ol__wushen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ol__wushen"] = "武神",
  [":ol__wushen"] = "锁定技，你的<font color='red'>♥</font>手牌视为【杀】；你使用<font color='red'>♥</font>【杀】无距离次数限制且不能被响应。",

  ["$ol__wushen1"] = "千里追魂，一刀索命！",
  ["$ol__wushen2"] = "鬼龙斩月刀！",
}

wushen:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wushen.name) and
      data.card.trueName == "slash" and data.card.suit == Card.Heart
  end,
  on_use = function(self, event, target, player, data)
    if not data.extraUse then
      data.extraUse = true
      player:addCardUseHistory(data.card.trueName, -1)
    end
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})
wushen:addEffect("filter", {
  mute = true,
  card_filter = function(self, to_select, player)
    return player:hasSkill(wushen.name) and to_select.suit == Card.Heart and
    table.contains(player:getCardIds("h"), to_select.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", Card.Heart, card.number)
  end,
})
wushen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(wushen.name) and skill.trueName == "slash_skill" and card.suit == Card.Heart
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(wushen.name) and skill.trueName == "slash_skill" and card.suit == Card.Heart
  end,
})

return wushen
