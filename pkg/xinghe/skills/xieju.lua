local xieju = fk.CreateSkill{
  name = "xieju",
}

Fk:loadTranslationTable{
  ["xieju"] = "偕举",
  [":xieju"] = "出牌阶段限一次，你可以选择令任意名本回合成为过牌的目标的角色，这些角色依次可以将一张黑色牌当【杀】使用。",

  ["#xieju"] = "偕举：选择任意名角色，这些角色可以将一张黑色牌当【杀】使用",
  ["#xieju-slash"] = "偕举：你可以将一张黑色牌当【杀】使用",

  ["$xieju1"] = "今举大义，誓与仲恭共死。",
  ["$xieju2"] = "天降大任，当与志士同忾。",
}

xieju:addAcquireEffect(function (self, player, is_start)
  if player.room.current == player then
    local room = player.room
    local mark = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      for _, p in ipairs(use.tos) do
        table.insertIfNeed(mark, p.id)
      end
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "xieju-turn", mark)
  end
end)

xieju:addEffect("active", {
  anim_type = "offensive",
  prompt = "#xieju",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xieju.name, Player.HistoryPhase) == 0 and player:getMark("xieju-turn") ~= 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return table.contains(player:getTableMark("xieju-turn"), to_select.id)
  end,
  on_use = function(self, room, effect)
    room:sortByAction(effect.tos)
    for _, target in ipairs(effect.tos) do
      if not target.dead then
        room:askToUseVirtualCard(target, {
          name = "slash",
          skill_name = xieju.name,
          prompt = "#xieju-slash",
          cancelable = true,
          extra_data = {
            bypass_times = true,
            extraUse = true,
          },
          card_filter = {
            n = 1,
            pattern = ".|.|spade,club",
          },
          skip = true,
        })
      end
    end
  end,
})

xieju:addEffect(fk.TargetConfirmed, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(xieju.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "xieju-turn", target.id)
  end,
})

return xieju
