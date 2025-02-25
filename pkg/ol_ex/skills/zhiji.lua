local this = fk.CreateSkill {
  name = "ol_ex__zhiji",
  frequency = Skill.Wake,
}

this:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and
      player:usedSkillTimes(this.name, Player.HistoryGame) == 0 and
      (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  can_wake = function(self, event, target, player, data)
    return player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(player, { choices = choices, skill_name = this.name})
    if choice == "draw2" then
      player:drawCards(2, this.name)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = this.name
      })
    end
    if player.dead then return false end
    room:changeMaxHp(player, -1)
    if player.dead then return false end
    room:handleAddLoseSkills(player, "ex__guanxing", nil)
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__zhiji"] = "志继",
  [":ol_ex__zhiji"] = "觉醒技，准备阶段或结束阶段，若你没有手牌，你回复1点体力或摸两张牌，然后减1点体力上限，获得“观星”。",

  ["$ol_ex__zhiji1"] = "丞相遗志，不死不休！",
  ["$ol_ex__zhiji2"] = "大业未成，矢志不渝！",
}

return this
