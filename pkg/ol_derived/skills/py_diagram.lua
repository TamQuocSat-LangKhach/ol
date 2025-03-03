local skill = fk.CreateSkill {
  name = "#py_diagram_skill",
  tags = { Skill.Compulsory },
  attached_equip = "py_diagram",
}

Fk:loadTranslationTable{
  ["#py_diagram_skill"] = "奇门八卦",
}

skill:addEffect(fk.PreCardEffect, {
  can_trigger = function(self, event, target, player, data)
    return data.to == player and player:hasSkill(skill.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data.nullified = true
  end,
})

return skill
