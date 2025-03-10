local yifa = fk.CreateSkill{
  name = "yifa",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yifa"] = "仪法",
  [":yifa"] = "锁定技，当其他角色使用【杀】或黑色普通锦囊牌指定你为目标后，其手牌上限-1直到其回合结束。",

  ["@yifa"] = "仪法",

  ["$yifa1"] = "仪法不明，则实不称名。",
  ["$yifa2"] = "仪法明晰，则长治久安。",
}

yifa:addEffect(fk.TargetSpecified, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(yifa.name) and data.firstTarget and
      table.contains(data.use.tos, player) and
      (data.card.trueName == "slash" or (data.card.color == Card.Black and data.card:isCommonTrick()))
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "@yifa", 1)
  end,
})
yifa:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@yifa") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@yifa", 0)
  end,
})
yifa:addEffect("maxcards", {
  correct_func = function(self, player)
    return -player:getMark("@yifa")
  end,
})

return yifa
