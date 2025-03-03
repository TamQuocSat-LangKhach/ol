local skill = fk.CreateSkill {
  name = "#py_robe_skill",
  tags = { Skill.Compulsory },
  attached_equip = "py_robe",
}

Fk:loadTranslationTable{
  ["#py_robe_skill"] = "红棉百花袍",
}

skill:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.damageType ~= fk.NormalDamage
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

return skill
