local feibai = fk.CreateSkill{
  name = "feibai",
  tags = { Skill.Switch, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["feibai"] = "飞白",
  [":feibai"] = "转换技，锁定技，阳：当你的非黑色牌造成伤害时，此伤害值+1；阴：当你的非红色牌回复体力时，此回复值+1。",

  [":feibai_yang"] = "转换技，锁定技，"..
  "<font color=\"#E0DB2F\">阳：当你的非黑色牌造成伤害时，此伤害值+1；</font>"..
  "<font color=\"gray\">阴：当你的非红色牌回复体力时，此回复值+1。</font>",
  [":feibai_yin"] = "转换技，锁定技，"..
  "<font color=\"gray\">阳：当你的非黑色牌造成伤害时，此伤害值+1；</font>"..
  "<font color=\"#E0DB2F\">阴：当你的非红色牌回复体力时，此回复值+1。</font>",

  ["$feibai1"] = "字之体势，一笔而成。",
  ["$feibai2"] = "超前绝伦，独步无双。",
}

feibai:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(feibai.name) and
      player:getSwitchSkillState(feibai.name, false) == fk.SwitchYang and
      data.card and data.card.color ~= Card.Black
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})
feibai:addEffect(fk.PreHpRecover, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(feibai.name) and
      player:getSwitchSkillState(feibai.name, false) == fk.SwitchYin and
      data.recoverBy and data.recoverBy == player and data.card and data.card.color ~= Card.Red
  end,
  on_use = function(self, event, target, player, data)
    data:changeRecover(1)
  end,
})

return feibai
