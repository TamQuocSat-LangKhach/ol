local juejue = fk.CreateSkill{
  name = "juejueh",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["juejueh"] = "玨玨",
  [":juejueh"] = "锁定技，当你使用【杀】【闪】【桃】【酒】时（每种牌名限一次），你令此牌的伤害值基数及回复值基数+1且不计次数，"..
  "此牌结算结束后，你获得之。",

  ["$juejueh1"] = "打虎亲兄弟，上阵父子兵！",
  ["$juejueh2"] = "你伪汉五虎，可敌不过我韩家五虎！",
}

juejue:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juejue.name) and
      table.contains({"slash", "jink", "peach", "analeptic"}, data.card.trueName) and
      not table.contains(player:getTableMark("juejueh_used"), data.card.trueName)
  end,
  on_use = function (self, event, target, player, data)
    player.room:addTableMark(player, "juejueh_used", data.card.trueName)
    data.additionalRecover = (data.additionalRecover or 0) + 1
    data.additionalDamage = (data.additionalDamage or 0) + 1
    if not data.extraUse then
      player:addCardUseHistory(data.card.trueName, -1)
      data.extraUse = true
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.juejueh = player
  end,
})
juejue:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.juejueh == player and not player.dead and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, juejue.name)
  end,
})

juejue:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "juejueh_used", 0)
end)

return juejue
