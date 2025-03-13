local zhiri = fk.CreateSkill{
  name = "zhiri",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["zhiri"] = "炙日",
  [":zhiri"] = "觉醒技，准备阶段，若你的“焚”数不小于3，你减1点体力上限，获得〖心惔〗。",

  ["$zhiri1"] = "好舒服，这太阳的力量！",
  ["$zhiri2"] = "你以为这样就已经结束了？",
}

zhiri:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhiri.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(zhiri.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("fentian_burn") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "xintan")
  end,
})

return zhiri
