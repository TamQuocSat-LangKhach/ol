local moucheng = fk.CreateSkill{
  name = "moucheng",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["moucheng"] = "谋逞",
  [":moucheng"] = "觉醒技，准备阶段，若你发动〖连计〗令目标角色使用【杀】造成过伤害，则你失去〖连计〗，获得〖矜功〗。",

  ["$moucheng1"] = "董贼伏诛，天下太平！",
  ["$moucheng2"] = "叫天不应，叫地不灵，今天就是你的死期！",
}

moucheng:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(moucheng.name) and player.phase == Player.Start and
      player:usedSkillTimes(moucheng.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark(moucheng.name) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-lianji|jingong")
  end,
})

return moucheng
