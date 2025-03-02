local diaoling = fk.CreateSkill{
  name = "diaoling",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["diaoling"] = "调令",
  [":diaoling"] = "觉醒技，准备阶段，若你发动〖募兵〗累计获得了至少六张【杀】、伤害锦囊牌和武器牌，你回复1点体力或摸两张牌，并修改〖募兵〗："..
  "多亮出一张牌，且获得的牌可以任意交给其他角色。",

  ["$diaoling1"] = "兵甲已足，当汇集三军。",
  ["$diaoling2"] = "临军告急，当遣将急援。",
}

diaoling:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(diaoling.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(diaoling.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@mubing") > 5
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@mubing", 0)
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = diaoling.name,
    })
    if choice == "draw2" then
      player:drawCards(2, diaoling.name)
    else
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = diaoling.name,
      }
    end
  end,
})

return diaoling
