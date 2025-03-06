local fenxun = fk.CreateSkill{
  name = "ol__fenxun",
}

Fk:loadTranslationTable{
  ["ol__fenxun"] = "奋迅",
  [":ol__fenxun"] = "出牌阶段限一次，你可以令你本回合计算与一名其他角色的距离视为1。然后本回合的结束阶段，若你本回合未对其造成过伤害，"..
  "你弃置一张牌。",

  ["#ol__fenxun"] = "奋迅：选择一名其他角色，本回合计算与其的距离视为1",

  ["$ol__fenxun1"] = "奋起直击，一战决生死！",
  ["$ol__fenxun2"] = "疾锋之刃，杀出一条血路！",
}

fenxun:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol__fenxun",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(fenxun.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:addTableMark(player, "ol__fenxun-turn", effect.tos[1].id)
  end,
})
fenxun:addEffect("distance", {
  fixed_func = function(self, from, to)
    if table.contains(from:getTableMark("ol__fenxun-turn"), to.id) then
      return 1
    end
  end,
})
fenxun:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Finish and player:getMark("ol__fenxun-turn") ~= 0 then
      local mark = player:getTableMark("ol__fenxun-turn")
      player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e)
        local damage = e.data
        if damage.from == player then
          table.removeOne(mark, damage.to.id)
        end
      end, Player.HistoryTurn)
      if #mark > 0 then
        event:setCostData(self, {extra_data = #mark})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).extra_data
    for _ = 1, n do
      if player.dead or player:isNude() then return end
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = fenxun.name,
        cancelable = false,
      })
    end
  end,
})

return fenxun
