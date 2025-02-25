local this = fk.CreateSkill{ name = "ol_ex__qinxue" }

this:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and
      (player.phase == Player.Start or player.phase == Player.Finish) and
      player:usedSkillTimes(this.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return (player:getHandcardNum() - player.hp > 1)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return false end
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(player, { choices = choices, skillName = this.name})
    if choice == "draw2" then
      room:drawCards(player, 2, this.name)
    elseif choice == "recover" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = this.name
      })
    end
    if player.dead then return false end
    room:handleAddLoseSkills(player, "gongxin", nil)
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__qinxue"] = "勤学",
  [":ol_ex__qinxue"] = "觉醒技，准备阶段或结束阶段，若你的手牌数比体力值多2或更多，你减1点体力上限，回复1点体力或摸两张牌，然后获得技能〖攻心〗。",
  
  ["$ol_ex__qinxue1"] = "士别三日，刮目相看！",
  ["$ol_ex__qinxue2"] = "吴下阿蒙，今非昔比！",
}

return this