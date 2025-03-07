local gangzhi = fk.CreateSkill{
  name = "gangzhi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["gangzhi"] = "刚直",
  [":gangzhi"] = "锁定技，其他角色对你造成的伤害、你对其他角色造成的伤害均视为体力流失。",

  ["$gangzhi1"] = "只恨箭支太少，不能射杀汝等！",
  ["$gangzhi2"] = "死便死，降？断不能降！",
}

gangzhi:addEffect(fk.PreDamage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gangzhi.name) and
      ((target == player and data.to ~= player) or
      (data.from and data.from ~= player and data.to == player))
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, data.damage, gangzhi.name)
    data:preventDamage()
  end,
})

return gangzhi
