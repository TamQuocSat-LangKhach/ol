local baixiang = fk.CreateSkill{
  name = "qin__baixiang",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["qin__baixiang"] = "拜相",
  [":qin__baixiang"] = "觉醒技，准备阶段，若你的手牌数不小于体力值三倍，你回复体力至上限，然后获得〖仲父〗。",

  ["$qin__baixiang"] = "入秦拜相，权倾朝野！",
}

baixiang:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(baixiang.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(baixiang.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getHandcardNum() >= 3 * player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover{
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = baixiang.name,
      }
      if player.dead then return end
    end
    room:handleAddLoseSkills(player, "qin__zhongfu")
  end,
})

return baixiang
