local dengji = fk.CreateSkill{
  name = "dengji",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["dengji"] = "登极",
  [":dengji"] = "觉醒技，准备阶段，若你的“储”数不小于3，你减1点体力上限，获得所有“储”，获得〖奸雄〗和〖天行〗。",

  ["$dengji1"] = "登高位，享极乐。",
  ["$dengji2"] = "今日，便是我称帝之时。",
}

dengji:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dengji.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(dengji.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("caopi_chu") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    if #player:getPile("caopi_chu") > 0 then
      room:obtainCard(player, player:getPile("caopi_chu"), true, fk.ReasonJustMove, player, dengji.name)
      if player.dead then return end
    end
    room:handleAddLoseSkills(player, "ex__jianxiong|tianxing")
  end,
})

return dengji
