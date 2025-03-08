local yuanchou = fk.CreateSkill{
  name = "yuanchou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yuanchou"] = "怨仇",
  [":yuanchou"] = "锁定技，你使用的黑色【杀】无视目标角色防具，其他角色对你使用的黑色【杀】无视你的防具。",

  ["$yuanchou1"] = "鞭挞之仇，不共戴天！",
  ["$yuanchou2"] = "三将军怎可如此对待我二人！",
}

yuanchou:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuanchou.name) and
      data.card.trueName == "slash" and data.card.color == Card.Black
  end,
  on_use = function(self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})
yuanchou:addEffect(fk.TargetConfirmed, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuanchou.name) and
      data.card.trueName == "slash" and data.card.color == Card.Black
  end,
  on_use = function(self, event, target, player, data)
    player:addQinggangTag(data)
  end,
})

return yuanchou
