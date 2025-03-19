local chigang = fk.CreateSkill{
  name = "chigang",
  tags = { Skill.Switch, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chigang"] = "持纲",
  [":chigang"] = "转换技，锁定技，阳：你的判定阶段改为摸牌阶段；阴：你的判定阶段改为出牌阶段。",

  [":chigang_yang"] = "转换技，锁定技，<font color=\"#E0DB2F\">阳：你的判定阶段改为摸牌阶段；</font>阴：你的判定阶段改为出牌阶段。",
  [":chigang_yin"] = "转换技，锁定技，阳：你的判定阶段改为摸牌阶段；<font color=\"#E0DB2F\">阴：你的判定阶段改为出牌阶段。</font>",

  ["$chigang1"] = "秉承伦常，扶树纲纪。",
  ["$chigang2"] = "至尊临位，则朝野自肃。",
}

chigang:addEffect(fk.EventPhaseChanging, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chigang.name) and data.phase == Player.Judge
  end,
  on_use = function(self, event, target, player, data)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      data.phase = Player.Draw
    else
      data.phase = Player.Play
    end
  end,
})

return chigang
