local this = fk.CreateSkill {
  name = "ol_ex__zaoxian",
  frequency = Skill.Wake,
}

this:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and player.phase == Player.Start and
      player:usedSkillTimes(this.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("ol_ex__dengai_field") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "ol_ex__jixi", nil)
    player:gainAnExtraTurn()
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__zaoxian"] = "凿险",
  [":ol_ex__zaoxian"] = "觉醒技，准备阶段，若“田”的数量大于等于3，你减1点体力上限，然后获得“急袭”。此回合结束后，你获得一个额外回合。",
  
  ["$ol_ex__zaoxian1"] = "良田厚土，足平蜀道之难！",
  ["$ol_ex__zaoxian2"] = "效仿五丁开川，赢粮直捣黄龙！",
}

return this