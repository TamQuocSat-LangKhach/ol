local this = fk.CreateSkill {
  name = "ol_ex__hunzi",
}

this:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and
      player:usedSkillTimes(this.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player.hp == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return false end
    room:handleAddLoseSkills(player, "ex__yingzi|yinghun", nil)
  end,
})

this:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target and target.phase == Player.Finish and not target.dead and player:usedSkillTimes(this.name, Player.HistoryTurn) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, this.name, "support")
    local choices = {"ol_ex__hunzi_draw"}
    if player:isWounded() then
      table.insert(choices, "ol_ex__hunzi_recover")
    end
    local choice = room:askToChoice(player, { choices = choices, skill_name = this.name, prompt = "#ol_ex__hunzi-choice"})
    if choice == "ol_ex__hunzi_draw" then
      player:drawCards(2, this.name)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = this.name
      })
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__hunzi"] = "魂姿",
  [":ol_ex__hunzi"] = "觉醒技，准备阶段，若你的体力值为1，你减1点体力上限，获得“英姿”和“英魂”。本回合结束阶段，你摸两张牌或回复1点体力。",
  
  ["#ol_ex__hunzi-choice"] = "魂姿：选择摸两张牌或者回复1点体力",
  ["ol_ex__hunzi_draw"] = "摸两张牌",
  ["ol_ex__hunzi_recover"] = "回复1点体力",
  
  ["$ol_ex__hunzi1"] = "江东新秀，由此崛起。",
  ["$ol_ex__hunzi2"] = "看汝等大展英气！",
}

return this