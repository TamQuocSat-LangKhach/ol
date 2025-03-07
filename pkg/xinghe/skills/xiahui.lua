local xiahui = fk.CreateSkill{
  name = "xiahui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xiahui"] = "黠慧",
  [":xiahui"] = "锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌后，其不能使用、打出、弃置这些牌直到其扣减体力为止。",

  ["@@xiahui-inhand"] = "黠慧",
}

xiahui:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(xiahui.name) and card.color == Card.Black
  end,
})
xiahui:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(xiahui.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).color == Card.Black and table.contains(move.to:getCardIds("h"), info.cardId) then
            room:setCardMark(Fk:getCardById(info.cardId), "@@xiahui-inhand", 1)
          end
        end
      end
    end
  end,
})
xiahui:addEffect(fk.HpChanged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.num < 0 and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@xiahui-inhand") > 0
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), "@@xiahui-inhand", 0)
    end
  end,
})
xiahui:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
      return table.find(cards, function(id)
        return Fk:getCardById(id):getMark("@@xiahui-inhand") > 0
      end)
  end,
  prohibit_response = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
      return table.find(cards, function(id)
        return Fk:getCardById(id):getMark("@@xiahui-inhand") > 0
      end)
  end,
  prohibit_discard = function(self, player, card)
    return card:getMark("@@xiahui-inhand") > 0
  end,
})

return xiahui
