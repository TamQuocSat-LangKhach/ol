local gaoshi = fk.CreateSkill{
  name = "gaoshi",
}

Fk:loadTranslationTable{
  ["gaoshi"] = "高视",
  [":gaoshi"] = "结束阶段，你可以连续展示牌堆顶牌，直到展示了本回合你使用过牌名的牌或展示了X张牌（X为你本回合发动〖捷悟〗的次数），\
  然后可以使用展示的牌。若你因此使用了所有亮出牌，你摸两张牌，否则将其余牌置入弃牌堆。",

  ["#gaoshi-use"] = "高视：你可以使用这些牌",
}

gaoshi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(gaoshi.name) and player.phase == Player.Finish and
      player:usedSkillTimes("jiewu", Player.HistoryTurn) > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local dat = {}
    player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
      if e.data.phase == Player.Play and e.end_id then
        table.insert(dat, {e.id, e.end_id})
      end
    end, Player.HistoryTurn)
    local names = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      if table.find(dat, function (info)
        return e.id > info[1] and e.id < info[2]
      end) then
        local use = e.data
        if use.from == player then
          table.insertIfNeed(names, use.card.trueName)
        end
      end
    end, Player.HistoryTurn)
    local all_cards = {}
    while #all_cards < player:usedSkillTimes("jiewu", Player.HistoryTurn) do
      local id = room:getNCards(#all_cards + 1)[#all_cards + 1]
      room:showCards(id)
      table.insert(all_cards, id)
      room:delay(600)
      if table.contains(names, Fk:getCardById(id).trueName) then
        break
      end
    end
    local cards = table.simpleClone(all_cards)
    while not player.dead do
      cards = table.filter(cards, function(id)
        return table.contains(room.draw_pile, id)
      end)
      if #cards == 0 then break end
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = gaoshi.name,
        prompt = "#gaoshi-use",
        extra_data = {
          bypass_times = true,
          extraUse = true,
          expand_pile = all_cards,
        },
        skip = true,
      })
      if use then
        table.removeOne(all_cards, use.card:getEffectiveId())
        room:useCard(use)
      else
        break
      end
    end
    if #all_cards == 0 and not player.dead then
      player:drawCards(2, gaoshi.name)
    else
      all_cards = table.filter(all_cards, function(id)
        return table.contains(room.draw_pile, id)
      end)
      if #all_cards > 0 then
        room:moveCardTo(all_cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, gaoshi.name, nil, true)
      end
    end
  end,
})

return gaoshi
