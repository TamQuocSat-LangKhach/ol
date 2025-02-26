local jiang = fk.CreateSkill {
  name = "ol_ex__jiang",
}
Fk:loadTranslationTable {
  ["ol_ex__jiang"] = "激昂",
  [":ol_ex__jiang"] = "当你使用【决斗】或红色【杀】指定目标后，或成为【决斗】或红色【杀】的目标后，你可以摸一张牌。"..
  "每回合首次有包含【决斗】或红色【杀】在内的牌因弃置而置入弃牌堆后，你可以失去1点体力，获得其中所有【决斗】和红色【杀】。",

  ["$ol_ex__jiang1"] = "策虽暗稚，窃有微志。",
  ["$ol_ex__jiang2"] = "收合流散，东据吴会。",
}

local U = require("packages/utility/utility")

jiang:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jiang.name) and data.firstTarget and
      ((data.card.trueName == "slash" and data.card.color == Card.Red) or data.card.name == "duel")
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jiang.name)
  end,
})

jiang:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jiang.name) and
      ((data.card.trueName == "slash" and data.card.color == Card.Red) or data.card.name == "duel")
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jiang.name)
  end,
})

jiang:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(jiang.name) then return end
    local x = player:getMark("jiang_record-turn")
    local room = player.room
    local move__event = room.logic:getCurrentEvent()
    if not move__event or (x > 0 and x ~= move__event.id) then return false end
    local searchJiangCards = function(move_data, findOne)
      local cards = {}
      for _, move in ipairs(move_data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if ((card.trueName == "slash" and card.color == Card.Red) or card.name == "duel") then
              table.insert(cards, info.cardId)
              if findOne then
                return cards
              end
            end
          end
        end
      end
      return cards
    end
    local cards = searchJiangCards(data, false)
    if #U.moveCardsHoldingAreaCheck(room, table.filter(cards, function (id)
      return room:getCardArea(id) == Card.DiscardPile
    end)) == 0 then return false end
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        if #searchJiangCards(e.data, true) > 0 then
          x = e.id
          room:setPlayerMark(player, "jiang_record-turn", x)
          return true
        end
        return false
      end, Player.HistoryTurn)
    end
    if x == move__event.id then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(self).cards)
    room:loseHp(player, 1, jiang.name)
    if player.dead then return false end
    cards = U.moveCardsHoldingAreaCheck(room, table.filter(cards, function (id)
      return room:getCardArea(id) == Card.DiscardPile
    end))
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, jiang.name, nil, true, player)
    end
  end,
})

return jiang