local skill = fk.CreateSkill {
  name = "#py_cloak_skill",
  tags = { Skill.Compulsory },
  attached_equip = "py_cloak",
}

Fk:loadTranslationTable{
  ["#py_cloak_skill"] = "国风玉袍",
}

skill:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return from ~= to and to:hasSkill(skill.name) and card and card:isCommonTrick()
  end,
})

return skill
