local skill = fk.CreateSkill {
  name = "#py_blade_skill",
  tags = { Skill.Compulsory },
  attached_equip = "py_blade",
}

Fk:loadTranslationTable{
  ["#py_blade_skill"] = "鬼龙斩月刀",
}

skill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.firstTarget and
      data.card.trueName == "slash" and data.card.color == Card.Red
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsive = true
  end,
})

return skill
