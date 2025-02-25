local U = require("packages.utility.utility")

local this = fk.CreateSkill {
  name = "ol_ex__jiang",
  anim_type = "drawcard",
}

local function jiang_condition(data)
  return ((data.card.trueName == "slash" and data.card.color == Card.Red) or data.card.name == "duel")
end

this:addEffect(fk.TargetSpecified, {
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(this.name) or player ~= target then return end
    return jiang_condition(data) and data.firstTarget
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, this.name)
  end,
})

this:addEffect(fk.TargetConfirmed, {
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(this.name) or player ~= target then return end
    return jiang_condition(data)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, this.name)
  end,
})

this:addEffect(fk.AfterCardsMove, {
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(this.name) then return end
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
      self.cost_data = cards
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(self.cost_data)
    room:loseHp(player, 1, this.name)
    if player.dead then return false end
    cards = U.moveCardsHoldingAreaCheck(room, table.filter(cards, function (id)
      return room:getCardArea(id) == Card.DiscardPile
    end))
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, this.name, nil, true, player.id)
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__jiang"] = "激昂",
  [":ol_ex__jiang"] = "当你使用【决斗】或红色【杀】指定目标后，或成为【决斗】或红色【杀】的目标后，你可以摸一张牌。每回合首次有包含【决斗】或红色【杀】在内的牌因弃置而置入弃牌堆后，你可以失去1点体力获得其中所有【决斗】和红色【杀】。",

  ["$ol_ex__jiang1"] = "策虽暗稚，窃有微志。",
  ["$ol_ex__jiang2"] = "收合流散，东据吴会。",
}

return this