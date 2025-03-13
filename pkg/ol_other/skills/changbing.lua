local changbing = fk.CreateSkill{
  name = "qin__changbing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__changbing"] = "长兵",
  [":qin__changbing"] = "锁定技，你的攻击范围+2。"
}

changbing:addEffect("atkrange", {
  correct_func = function (self, from, to)
    if from:hasSkill(changbing.name) then
      return 2
    end
  end,
})

return changbing
