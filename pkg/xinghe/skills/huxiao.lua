local huxiao = fk.CreateSkill{
  name = "ol__huxiao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__huxiao"] = "虎啸",
  [":ol__huxiao"] = "锁定技，当你对一名角色造成火焰伤害后，该角色摸一张牌，然后本回合你对其使用牌无次数限制。",

  ["@@ol__huxiao-turn"] = "虎啸",

  ["$ol__huxiao1"] = "看我连招发动。",
  ["$ol__huxiao2"] = "想躲过我的攻击，不可能。",
}

huxiao:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huxiao.name) and
      data.damageType == fk.FireDamage and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    data.to:drawCards(1, huxiao.name)
    if data.to.dead then return end
    player.room:addTableMarkIfNeed(data.to, "@@ol__huxiao-turn", player.id)
  end,
})
huxiao:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(to:getTableMark("@@ol__huxiao-turn"), player.id)
  end,
})

return huxiao
