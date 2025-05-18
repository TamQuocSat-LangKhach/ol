local zhujiu = fk.CreateSkill{
  name = "zhujiu",
}

Fk:loadTranslationTable{
  ["zhujiu"] = "煮酒",
  [":zhujiu"] = "你可以将至少X+1张牌当【酒】使用（X为你本回合使用【酒】次数），若不均为♣，此技能本回合失效。",

  ["#zhujiu"] = "煮酒：你可以将至少%arg张牌当【酒】使用，若不均为♣则本回合失效",

  ["$zhujiu1"] = "当下青梅正好，可为佐酒之资。",
  ["$zhujiu2"] = "枝头梅子青青，值煮酒正熟，不可不赏。",
}

zhujiu:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
      local use = e.data
      return use.from == player and use.card.trueName == "analeptic"
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "zhujiu-turn", n)
  end
end)

zhujiu:addEffect("viewas", {
  anim_type = "special",
  pattern = "analeptic",
  prompt = function (self, player)
    return "#zhujiu:::"..(player:getMark("zhujiu-turn") + 1)
  end,
  handly_pile = true,
  card_filter = Util.TrueFunc,
  view_as = function(self, player, cards)
    if #cards < player:getMark("zhujiu-turn") + 1 then return end
    local card = Fk:cloneCard("analeptic")
    card:addSubcards(cards)
    card.skillName = zhujiu.name
    return card
  end,
  before_use = function (self, player, use)
    if not table.every(use.card.subcards, function (id)
      return Fk:getCardById(id).suit == Card.Club
    end) then
      player.room:invalidateSkill(player, zhujiu.name, "-turn")
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})
zhujiu:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhujiu.name, true) and data.card.trueName == "analeptic"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "zhujiu-turn", 1)
  end,
})

return zhujiu
