local qiangshou = fk.CreateSkill{
  name = "qiangshou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qiangshou"] = "羌首",
  [":qiangshou"] = "锁定技，若你的装备区里有宝物牌，你至其他角色的距离-1。",
}

qiangshou:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(qiangshou.name) and #from:getEquipments(Card.SubtypeTreasure) > 0 then
      return -1
    end
  end,
})

return qiangshou
