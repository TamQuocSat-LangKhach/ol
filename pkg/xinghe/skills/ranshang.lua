local ranshang = fk.CreateSkill{
  name = "ranshang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ranshang"] = "燃殇",
  [":ranshang"] = "锁定技，当你受到1点火焰伤害后，你获得1枚“燃”标记；结束阶段，你失去X点体力（X为“燃”标记的数量）。",

  ["@wutugu_ran"] = "燃",

  ["$ranshang1"] = "战火燃尽英雄胆！",
  ["$ranshang2"] = "尔等，竟如此歹毒！",
}

ranshang:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@wutugu_ran", 0)
end)

ranshang:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ranshang.name) and data.damageType == fk.FireDamage
  end,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@wutugu_ran", data.damage)
  end,
})
ranshang:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ranshang.name) and player.phase == Player.Finish and
      player:getMark("@wutugu_ran") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, player:getMark("@wutugu_ran"), ranshang.name)
  end,
})

return ranshang
