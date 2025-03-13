local limu = fk.CreateSkill{
  name = "qin__limu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__limu"] = "立木",
  [":qin__limu"] = "锁定技，你使用的普通锦囊牌不能被抵消。",

  ["$qin__limu"] = "立木之言，汇聚民心。",
}

limu:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(limu.name) and data.card:isCommonTrick()
  end,
  on_use = function(self, event, target, player, data)
    data.unoffsetableList = player.room.players
  end,
})

return limu
