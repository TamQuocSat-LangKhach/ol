local chuiti = fk.CreateSkill{
  name = "chuiti",
}

Fk:loadTranslationTable{
  ["chuiti"] = "垂涕",
  [":chuiti"] = "每回合限一次，当你或装备区有“宝梳”的角色的一张牌因弃置而置入弃牌堆后，你可以使用之（有次数限制）。",

  ["#chuiti-use"] = "垂涕：你可以使用其中一张牌",

  ["$chuiti1"] = "悲愁垂涕，三日不食。",
  ["$chuiti2"] = "宜数涕泣，示忧愁也。",
}

local U = require "packages/utility/utility"

chuiti:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(chuiti.name) or player:usedSkillTimes(chuiti.name, Player.HistoryTurn) > 0 then return false end
    local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn_event == nil then return end
    local ids = {}
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and move.from and
        (move.from == player or
        table.find(move.from:getEquipments(Card.SubtypeTreasure), function (id)
          return table.contains({"jade_comb", "rhino_comb", "golden_comb"}, Fk:getCardById(id).name)
        end)) then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            table.contains(player.room.discard_pile, info.cardId) then
            if player:canUse(Fk:getCardById(info.cardId), {bypass_times = false}) then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end
    ids = U.moveCardsHoldingAreaCheck(player.room, ids)
    if #ids > 0 then
      event:setCostData(self, {cards = ids})
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.simpleClone(event:getCostData(self).cards)
    local use = room:askToUseRealCard(player, {
      pattern = ids,
      skill_name = chuiti.name,
      prompt = "#chuiti-use",
      extra_data = {
        bypass_times = false,
        expand_pile = ids,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

return chuiti
