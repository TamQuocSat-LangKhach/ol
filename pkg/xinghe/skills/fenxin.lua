local fenxin = fk.CreateSkill{
  name = "ol__fenxin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__fenxin"] = "焚心",
  [":ol__fenxin"] = "锁定技，当一名其他角色死亡后，根据其身份修改〖竭缘〗：忠臣，你减少伤害无体力值限制；反贼，你增加伤害无体力值限制；"..
  "内奸，弃置牌时无颜色限制且可以弃置装备牌。",

  ["$ol__fenxin1"] = "你的身份，我已为你抹去。",
  ["$ol__fenxin2"] = "伤我心神，焚汝身骨。",
}

fenxin:addEffect(fk.Deathed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fenxin.name) and table.contains({"loyalist", "rebel", "renegade"}, target.role) and
      not table.contains(player:getTableMark(fenxin.name), target.role)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, fenxin.name, target.role)
  end,
})

return fenxin
