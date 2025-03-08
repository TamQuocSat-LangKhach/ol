local chouhai = fk.CreateSkill{
  name = "chouhai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chouhai"] = "仇海",
  [":chouhai"] = "锁定技，当你受到伤害时，若你没有手牌，你令此伤害+1。",

  ["$chouhai1"] = "哼，树敌三千又如何？",
  ["$chouhai2"] = "不发狂，就灭亡！",
}

chouhai:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chouhai.name) and player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return chouhai
