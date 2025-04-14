local gaoshi = fk.CreateSkill{
  name = "gaoshi",
}

Fk:loadTranslationTable{
  ["gaoshi"] = "高视",
  [":gaoshi"] = "结束阶段，你可以亮出牌堆顶X张牌（X为你本回合发动〖捷悟〗的次数），然后可以使用其中本回合出牌阶段你未使用过的牌名的牌。"..
  "若你因此使用了所有亮出牌，你摸两张牌。",

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
    local all_cards = room:getNCards(player:usedSkillTimes("jiewu", Player.HistoryTurn))
    local tempIds = table.simpleClone(all_cards)
    room:turnOverCardsFromDrawPile(player, all_cards, gaoshi.name)
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
    local cards = table.filter(all_cards, function (id)
      return not table.contains(names, Fk:getCardById(id).trueName)
    end)
    while not player.dead do
      cards = table.filter(cards, function(id)
        return room:getCardArea(id) == Card.Processing
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
    end

    room:cleanProcessingArea(tempIds, gaoshi.name)
  end,
})

return gaoshi
