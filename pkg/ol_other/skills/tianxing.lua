local tianxing = fk.CreateSkill{
  name = "tianxing",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["tianxing"] = "天行",
  [":tianxing"] = "觉醒技，准备阶段，若你的“储”数不小于3，你减1点体力上限，获得所有“储”，失去〖储元〗，并获得下列技能中的一项："..
  "〖仁德〗、〖制衡〗、〖乱击〗、〖放权〗。",

  ["#tianxing-choice"] = "天行：选择获得的技能",

  ["$tianxing1"] = "孤之行，天之意。",
  ["$tianxing2"] = "我做的决定，便是天的旨意。",
}

tianxing:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tianxing.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(tianxing.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("caopi_chu") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    if #player:getPile("caopi_chu") > 0 then
      room:obtainCard(player, player:getPile("caopi_chu"), true, fk.ReasonJustMove, player, tianxing.name)
      if player.dead then return end
    end
    room:handleAddLoseSkills(player, "-chuyuan")
    if player.dead then return end
    local all_choices = {"ex__rende", "ex__zhiheng", "ol_ex__luanji", "ol_ex__fangquan"}
    local choices = table.filter(all_choices, function (s)
      return not player:hasSkill(s, true)
    end)
    if #choices > 0 then
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = tianxing.name,
        prompt = "#tianxing-choice",
        detailed = true,
        all_choices = all_choices,
      })
      room:handleAddLoseSkills(player, choice)
    end
  end,
})

return tianxing
