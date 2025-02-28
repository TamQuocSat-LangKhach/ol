local guliang = fk.CreateSkill{
  name = "guliang",
}

Fk:loadTranslationTable{
  ["guliang"] = "固粮",
  [":guliang"] = "每回合限一次，其他角色对你使用牌时，你可令此牌对你无效，若如此做，你无法响应其对你使用的牌直到回合结束。",

  ["#guliang-invoke"] = "固粮：是否令 %dest 对你使用的%arg无效，本回合你不能响应其对你使用的牌？",
  ["@@guliang-turn"] = "固粮",
}

guliang:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guliang.name) and data.from ~= player and
      player:usedSkillTimes(guliang.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = guliang.name,
      prompt = "#guliang-invoke::"..data.from.id..":"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    if data.card.sub_type == Card.SubtypeDelayedTrick then
      data:cancelTarget(player)
    else
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      table.insertIfNeed(data.use.nullifiedTargets, player)
    end
    player.room:setPlayerMark(player, "@@guliang-turn", data.from.id)
  end,
})
guliang:addEffect(fk.CardUsing, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@guliang-turn") == target.id and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.contains(data.tos, player)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertIfNeed(data.disresponsiveList, player)
  end,
})

return guliang
