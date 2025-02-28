local jingce = fk.CreateSkill{
  name = "ol_ex__jingce",
}

Fk:loadTranslationTable{
  ["ol_ex__jingce"] = "精策",
  [":ol_ex__jingce"] = "你每于回合内使用一种花色的手牌，本回合的手牌上限便+1；一名角色的出牌阶段结束时，你可以摸X张牌（X为你本回合使用过牌的类别数）。",
}

jingce:addEffect(fk.CardUsing, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jingce.name) and
      player.room.current == player and data.card.suit ~= Card.NoSuit and data:IsUsingHandcard(player) and
      not table.contains(player:getTableMark("ol_ex__jingce-turn"), data.card.suit)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 1)
    room:addTableMark(player, "ol_ex__jingce-turn", data.card.suit)
  end,
})
jingce:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jingce.name) and data.phase == Player.Play and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local types = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      if e.data.from == player then
        table.insertIfNeed(types, e.data.card.type)
      end
    end, Player.HistoryTurn)
    player:drawCards(#types, jingce.name)
  end,
})

return jingce