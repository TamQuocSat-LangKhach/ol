local tunjiang = fk.CreateSkill{
  name = "tunjiang",
}

Fk:loadTranslationTable{
  ["tunjiang"] = "屯江",
  [":tunjiang"] = "结束阶段，若你未跳过本回合的出牌阶段，且你于本回合出牌阶段内未使用牌指定过其他角色为目标，你可以摸X张牌（X为全场势力数）。",

  ["$tunjiang1"] = "皇叔勿惊，吾与关将军已到。",
  ["$tunjiang2"] = "江夏冲要之地，孩儿愿往守之。",
}

tunjiang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tunjiang.name) and player.phase == Player.Finish and
      not player.skipped_phases[Player.Play] then
      local phase_events = player.room.logic:getEventsOfScope(GameEvent.Phase, 999, function (e)
        return e.data.phase == Player.Play
      end, Player.HistoryTurn)
      return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from and table.find(use.tos, function (p)
          return p ~= player
        end) and
        table.find(phase_events, function (phase)
          return phase.id < e.id and phase.end_id > e.id
        end) ~= nil
      end, Player.HistoryTurn) == 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player:drawCards(#kingdoms, tunjiang.name)
  end,
})

return tunjiang
