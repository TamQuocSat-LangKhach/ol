local quanjiu = fk.CreateSkill{
  name = "quanjiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["quanjiu"] = "劝酒",
  [":quanjiu"] = "锁定技，你的【酒】和【酗酒】均视为【杀】，且使用时不计入次数限制。",

  ["$quanjiu1"] = "大敌当前，怎可松懈畅饮？",
  ["$quanjiu2"] = "乌巢重地，不宜饮酒！",
}

quanjiu:addEffect("filter", {
  anim_type = "offensive",
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(quanjiu.name) and card.trueName == "analeptic" and
      (table.contains(player:getCardIds("h"), card.id) or isJudgeEvent)
  end,
  view_as = function(self, player, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = quanjiu.name
    return c
  end,
})
quanjiu:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, quanjiu.name)
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end,
})
quanjiu:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, quanjiu.name)
  end,
})

return quanjiu
