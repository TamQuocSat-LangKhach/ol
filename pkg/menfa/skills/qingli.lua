local qingli = fk.CreateSkill{
  name = "qingli",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qingli"] = "清励",
  [":qingli"] = "锁定技，每名角色的回合结束时，你将手牌摸至手牌上限（至多摸5张）。",

  ["$qingli1"] = "",
  ["$qingli2"] = "",
}

qingli:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qingli.name) and player:getHandcardNum() < player:getMaxCards()
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.min(5, player:getMaxCards() - player:getHandcardNum()), qingli.name)
  end,
})

return qingli