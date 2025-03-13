local cangchu = fk.CreateSkill{
  name = "guandu__cangchu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guandu__cangchu"] = "仓储",
  [":guandu__cangchu"] = "锁定技，游戏开始时，你获得三枚“粮”标记；当你受到1点火焰伤害后，你弃置一枚“粮”标记。",

  ["@guandu_grain"] = "粮",

  ["$guandu__cangchu1"] = "敌袭！速度整军，坚守营寨！",
  ["$guandu__cangchu2"] = "袁公所托，琼，必当死守！",
}

cangchu:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@guandu_grain", 0)
end)

cangchu:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(cangchu.name) and
      data.damageType == fk.FireDamage and player:getMark("@guandu_grain") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(cangchu.name, 1)
    room:notifySkillInvoked(player, cangchu.name, "negative")
    room:removePlayerMark(player, "@guandu_grain", 1)
  end,
})
cangchu:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(cangchu.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(cangchu.name, 2)
    room:notifySkillInvoked(player, cangchu.name, "special")
    room:addPlayerMark(player, "@guandu_grain", 3)
  end,
})

return cangchu
