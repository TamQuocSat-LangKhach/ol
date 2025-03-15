local mingjie = fk.CreateSkill{
  name = "mingjiew",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["mingjiew"] = "铭戒",
  [":mingjiew"] = "限定技，出牌阶段，你可以选择一名角色：直到其下回合结束，你使用牌可以额外指定其为目标；其下回合结束时，"..
  "你可以使用弃牌堆中此回合中被使用过的♠牌和被抵消过的牌。",

  ["#mingjiew"] = "铭戒：选择一名角色",
  ["@@mingjiew"] = "铭戒",
  ["#mingjiew-choose"] = "铭戒：你可以为此%arg额外指定任意名“铭戒”角色为目标",
  ["#mingjiew-use"] = "铭戒：你可以使用其中的牌",

  ["$mingjiew1"] = "大公至正，恪忠义于国。",
  ["$mingjiew2"] = "此生柱国之志，铭恪于胸。",
}

mingjie:addEffect("active", {
  anim_type = "control",
  prompt = "#mingjiew",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedEffectTimes(mingjie.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      if to_select == player then
        return player:getMark("mingjiew_disabled-turn") == 0
      else
        return not table.contains(to_select:getTableMark("@@mingjiew"), player.id)
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(target, "@@mingjiew", player.id)
    if target == player then
      room:setPlayerMark(player, "mingjiew_disabled-turn", 1)
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil or turn_event.data.who ~= player then
        room:setPlayerMark(player, "mingjiew_self", 0)
      else
        room:setPlayerMark(player, "mingjiew_self", turn_event.id)
      end
    end
  end,
})
mingjie:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and not player.dead and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      table.find(data:getExtraTargets({bypass_distances = true}), function (p)
        return table.contains(p:getTableMark("@@mingjiew"), player.id)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({bypass_distances = true}), function (p)
      return table.contains(p:getTableMark("@@mingjiew"), player.id)
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 9,
      targets = targets,
      skill_name = mingjie.name,
      prompt = "#mingjiew-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
  end,
})
mingjie:addEffect(fk.TurnEnd, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if table.contains(target:getTableMark("@@mingjiew"), player.id) and not player.dead then
      if player:getMark("mingjiew_disabled-turn") > 0 then return end
      local room = player.room
      local ids = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.card.suit == Card.Spade or use.cardsResponded then
          table.insertTableIfNeed(ids, Card:getIdList(use.card))
        end
      end, Player.HistoryTurn)
      ids = table.filter(ids, function (id)
        return table.contains(room.discard_pile, id)
      end)
      if #ids > 0 then
        event:setCostData(self, {cards = ids})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    while not player.dead do
      cards = table.filter(cards, function (id)
        return table.contains(room.discard_pile, id)
      end)
      if #cards == 0 then return end
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = mingjie.name,
        prompt = "#mingjiew-use",
        extra_data = {
          bypass_times = true,
          extraUse = true,
          expand_pile = cards,
        },
        skip = true,
      })
      if use then
        table.removeOne(cards, use.card:getEffectiveId())
        room:useCard(use)
      else
        break
      end
    end
  end,

  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@mingjiew") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("mingjiew_disabled-turn") > 0 and player:getMark("mingjiew_self") ~= 0 then
      room:setPlayerMark(player, "@@mingjiew", {player.id})
    else
      room:setPlayerMark(player, "@@mingjiew", 0)
      room:setPlayerMark(player, "mingjiew_self", 0)
    end
  end,
})

return mingjie
