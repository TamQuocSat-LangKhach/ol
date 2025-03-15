local shengmo = fk.CreateSkill{
  name = "shengmo",
}

Fk:loadTranslationTable{
  ["shengmo"] = "剩墨",
  [":shengmo"] = "你可以获得一张本回合进入弃牌堆的牌中一张不为点数最大且不为点数最小的牌，视为使用未以此法使用过的基本牌。",

  ["#shengmo"] = "剩墨：获得弃牌堆里的一张牌，视为使用一张基本牌",

  ["$shengmo1"] = "",
  ["$shengmo2"] = "",
}

local U = require "packages/utility/utility"

---@return integer[]
local function getShengmoCards(player)
  return table.filter(player:getTableMark("shengmo_cards-turn"), function (id)
    return not table.every(player:getTableMark("shengmo_cards-turn"), function (id2)
      return Fk:getCardById(id2).number <= Fk:getCardById(id).number
    end) and
    not table.every(player:getTableMark("shengmo_cards-turn"), function (id2)
      return Fk:getCardById(id2).number >= Fk:getCardById(id).number
    end)
  end)
end

shengmo:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#shengmo",
  expand_pile = function(self, player)
    return getShengmoCards(player)
  end,
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(shengmo.name, all_names, nil, player:getTableMark("shengmo_used"))
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getTableMark("shengmo_cards-turn"), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = shengmo.name
    self.cost_data = cards
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:addTableMark(player, "shengmo_used", use.card.trueName)
    room:obtainCard(player, self.cost_data, true, fk.ReasonJustMove, player, shengmo.name)
  end,
  enabled_at_play = function(self, player)
    return #getShengmoCards(player) > 0 and
      #player:getViewAsCardNames(shengmo.name, Fk:getAllCardNames("b"), nil, player:getTableMark("shengmo_used")) > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and
      #getShengmoCards(player) > 0 and
      #player:getViewAsCardNames(shengmo.name, Fk:getAllCardNames("b"), nil, player:getTableMark("shengmo_used")) > 0
  end,
})
shengmo:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(shengmo.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local ids = player:getTableMark("shengmo_cards-turn")
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(ids, info.cardId)
        end
      end
    end
    ids = table.filter(ids, function (id)
      return table.contains(room.discard_pile, id)
    end)
    room:setPlayerMark(player, "shengmo_cards-turn", ids)
  end,
})

shengmo:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local ids = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end, Player.HistoryTurn)
    ids = table.filter(ids, function (id)
      return table.contains(room.discard_pile, id)
    end)
    room:setPlayerMark(player, "shengmo_cards-turn", ids)
  end
end)

return shengmo
