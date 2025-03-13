local qixian = fk.CreateSkill{
  name = "qixian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qixian"] = "七弦",
  [":qixian"] = "锁定技，你的手牌上限为7。",
}

qixian:addEffect("maxcards", {
  fixed_func = function (self, player)
    if player:hasSkill(qixian.name) then
      return 7
    end
  end,
})

return qixian
