local yintian = fk.CreateSkill{
  name = "yintian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yintian"] = "隐天",
  [":yintian"] = "锁定技，每回合首次有角色回复体力后，你下次造成的伤害+1（无法叠加）。",

  ["@@yintian"] = "隐天",

  ["$yintian1"] = "",
  ["$yintian2"] = "",
}

yintian:addEffect(fk.HpRecover, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(yintian.name) and player:getMark("@@yintian") == 0 and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      local recover_events = player.room.logic:getEventsOfScope(GameEvent.Recover, 1, Util.TrueFunc, Player.HistoryTurn)
      return #recover_events == 1 and recover_events[1].data == data
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yintian", 1)
  end,
})
yintian:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@yintian") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yintian", 0)
    data:changeDamage(1)
  end,
})

return yintian
