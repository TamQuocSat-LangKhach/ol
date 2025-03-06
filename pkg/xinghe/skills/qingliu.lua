local qingliu = fk.CreateSkill{
  name = "qingliu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qingliu"] = "清流",
  [":qingliu"] = "锁定技，游戏开始时，你选择变为群或魏势力。你首次脱离濒死状态被救回后，你变更为另一个势力。",

  ["$qingliu1"] = "谁说这宦官，皆是大奸大恶之人？",
  ["$qingliu2"] = "咱家要让这天下人知道，宦亦有贤。",
}

qingliu:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qingliu.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdom = room:askToChoice(player, {
      choices = {"qun", "wei"},
      skill_name = qingliu.name,
      prompt = "AskForKingdom",
    })
    if kingdom ~= player.kingdom then
      room:changeKingdom(player, kingdom, true)
    end
  end,
})
qingliu:addEffect(fk.AfterDying, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(qingliu.name) and player:usedEffectTimes(self.name, Player.HistoryGame) == 0 then
      local dying_events = player.room.logic:getEventsOfScope(GameEvent.Dying, 1, function(e)
        return e.data.who == player
      end, Player.HistoryGame)
      return #dying_events > 0 and dying_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdoms = {"qun", "wei"}
    table.removeOne(kingdoms, player.kingdom)
    local kingdom = room:askToChoice(player, {
      choices = {"qun", "wei"},
      skill_name = qingliu.name,
      prompt = "AskForKingdom",
    })
    if kingdom ~= player.kingdom then
      room:changeKingdom(player, kingdom, true)
    end
  end,
})

return qingliu
