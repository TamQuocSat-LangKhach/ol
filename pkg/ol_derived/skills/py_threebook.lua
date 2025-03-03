local sk = fk.CreateSkill {
  name = "#py_threebook_skill",
  tags = { Skill.Compulsory },
  attached_equip = "py_threebook",
}

Fk:loadTranslationTable{
  ["#py_threebook_skill"] = "三略",
}

sk:addEffect("atkrange", {
  correct_func = function (self, from)
    if from:hasSkill(sk.name) then
      return 1
    end
  end,
})
sk:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(sk.name) then
      return 1
    end
  end,
})
sk:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill(sk.name) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return 1
    end
  end,
})

return sk
