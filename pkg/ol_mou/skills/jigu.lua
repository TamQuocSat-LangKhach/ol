local jigu = fk.CreateSkill{
  name = "jigud",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jigud"] = "积谷",
  [":jigud"] = "锁定技，一名角色于其出牌阶段外使用的牌置入弃牌堆后，若“谷”数小于你的体力上限，将其中的非<font color='red'>♥</font>牌置于"..
  "你的武将牌上，称为“谷”。体力上限与你相同的角色回合开始时，你用任意张手牌替换等量“谷”。",

  ["dengai_grain"] = "谷",
  ["#jigud-exchange"] = "积谷：用任意张手牌交换等量的“谷”",
}

local U = require "packages/utility/utility"

jigu:addEffect(fk.AfterCardsMove, {
  derived_piles = "dengai_grain",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jigu.name) and #player:getPile("dengai_grain") < player.maxHp then
      local room = player.room
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == nil and move.moveReason == fk.ReasonUse then
          local move_event = room.logic:getCurrentEvent()
          local use_event = move_event.parent
          if use_event ~= nil and use_event.event == GameEvent.UseCard then
            local use = use_event.data
            if use.from.phase ~= Player.Play then
              local card_ids = Card:getIdList(use.card)
              for _, info in ipairs(move.moveInfo) do
                if table.contains(card_ids, info.cardId) and table.contains(room.discard_pile, info.cardId) then
                  table.insertIfNeed(cards, info.cardId)
                end
              end
            end
          end
        end
      end
      cards = U.moveCardsHoldingAreaCheck(room, cards)
      cards = table.filter(cards, function (id)
        return Fk:getCardById(id).suit ~= Card.Heart
      end)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player:addToPile("dengai_grain", event:getCostData(self).cards, true, jigu.name, player)
  end,
})
jigu:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jigu.name) and target.maxHp == player.maxHp and #player:getPile("dengai_grain") > 0 and
      not player:isKongcheng()
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cids = room:askToArrangeCards(player, {
      skill_name = jigu.name,
      card_map = {
        player:getPile("dengai_grain"), player:getCardIds("h"),
        "dengai_grain", "$Hand"
      },
      prompt = "#jigud-exchange",
      cancelable = true,
    })
    U.swapCardsWithPile(player, cids[1], cids[2], jigu.name, "dengai_grain")
  end,
})

return jigu
