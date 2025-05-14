local quanbian = fk.CreateSkill{
  name = "quanbian",
}

Fk:loadTranslationTable{
  ["quanbian"] = "权变",
  [":quanbian"] = "当你于出牌阶段首次使用或打出一种花色的手牌时，你可以从牌堆顶X张牌中获得一张与此牌花色不同的牌，将其余牌以任意顺序置于牌堆顶。"..
  "出牌阶段，你至多使用X张非装备手牌。（X为你的体力上限）",

  ["@quanbian-phase"] = "权变",
  ["#quanbian-get"] = "权变：获得一张花色不同的牌",

  ["$quanbian1"] = "筹权谋变，步步为营。",
  ["$quanbian2"] = "随机应变，谋国窃权。",
}

local quanbian_spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(quanbian.name) and player.phase == Player.Play and
      data.card.suit ~= Card.NoSuit and data:isUsingHandcard(player) then
      local card_suit = data.card.suit
      local room = player.room
      local logic = room.logic
      local current_event = logic:getCurrentEvent()
      local mark_name = "quanbian_" .. data.card:getSuitString() .. "-phase"
      local mark = player:getMark(mark_name)
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data
          if use.from == player and use.card.suit == card_suit and e.data:isUsingHandcard(player) then
            mark = e.id
            return true
          end
        end, Player.HistoryPhase)
        logic:getEventsOfScope(GameEvent.RespondCard, 1, function (e)
          local use = e.data
          if use.from == player and use.card.suit == card_suit and e.data:isUsingHandcard(player) then
            mark = (mark == 0) and e.id or math.min(e.id, mark)
            return true
          end
        end, Player.HistoryPhase)
        room:setPlayerMark(player, mark_name, mark)
      end
      return mark == current_event.id
    end
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:addTableMark(player, "@quanbian-phase", data.card:getSuitString(true))
    self:doCost(event, target, player, data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_cards = room:getNCards(player.maxHp)
    local suits = {"spade", "club", "heart", "diamond"}
    table.remove(suits, data.card.suit)
    local cardmap = room:askToArrangeCards(player, {
      skill_name = quanbian.name,
      card_map = {all_cards, {}, "Top", "toObtain"},
      free_arrange = true,
      max_limit = {#all_cards, 1},
      min_limit = {0, 0},
      pattern = ".|.|"..table.concat(suits, ","),
    })
    for i = #cardmap[1], 1, -1 do
      table.removeOne(room.draw_pile, cardmap[1][i])
      table.insert(room.draw_pile, 1, cardmap[1][i])
    end
    if #cardmap[2] > 0 then
      room:obtainCard(player, cardmap[2][1], false, fk.ReasonPrey, player, quanbian.name)
    end
  end,
}

quanbian:addEffect(fk.CardUsing, quanbian_spec)
quanbian:addEffect(fk.CardResponding, quanbian_spec)

quanbian:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(quanbian.name) and player.phase == Player.Play and
      data.card.type ~= Card.TypeEquip and data:isUsingHandcard(player)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "quanbian-phase", 1)
  end,
})
quanbian:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:hasSkill(quanbian.name) and player.phase == Player.Play and player:getMark("quanbian-phase") >= player.maxHp and
      card and card.type ~= Card.TypeEquip then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})

return quanbian
