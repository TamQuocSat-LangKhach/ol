local huiqi = fk.CreateSkill{
  name = "huiqi",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["huiqi"] = "彗企",
  [":huiqi"] = "觉醒技，每个回合结束时，若本回合仅有包括你的三名角色成为过牌的目标，你回复1点体力并获得〖偕举〗。",

  ["$huiqi1"] = "今大星西垂，此天降清君侧之证。",
  ["$huiqi2"] = "彗星竟于西北，此罚天狼之兆。",
}

huiqi:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(huiqi.name) and player:usedSkillTimes(huiqi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      for _, p in ipairs(use.tos) do
        table.insertIfNeed(targets, p)
      end
    end, Player.HistoryTurn)
    return #targets == 3 and table.contains(targets, player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = huiqi.name
      }
    end
    room:handleAddLoseSkills(player, "xieju")
  end,
})

return huiqi
