local xugou = fk.CreateSkill{
  name = "shengxiao_xugou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shengxiao_xugou"] = "戌狗",
  [":shengxiao_xugou"] = "锁定技，红色【杀】对你无效；你使用红色【杀】无距离限制且伤害+1。",
}

xugou:addEffect(fk.PreCardEffect, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xugou.name) and data.card.trueName == "slash" and data.to == player and data.card.color == Card.Red
  end,
  on_use = function (self, event, target, player, data)
    data.nullified = true
  end,
})
xugou:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xugou.name) and
      data.card.trueName == "slash" and data.card.color == Card.Red
  end,
  on_use = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})
xugou:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card)
    return player:hasSkill(xugou.name) and card and card.trueName == "slash" and card.color == Card.Red
  end,
})

return xugou
