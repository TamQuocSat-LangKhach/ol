
local chunlao = fk.CreateSkill{
  name = "ol_ex__chunlao",
}

Fk:loadTranslationTable{
  ["ol_ex__chunlao"] = "醇醪",
  [":ol_ex__chunlao"] = "你或你相邻角色的【杀】因弃置进入弃牌堆后，将之置为“醇”。当一名角色处于濒死状态时，你可以将X张“醇”置入弃牌堆，"..
  "视为该角色使用一张【酒】（X为本轮以此法使用【酒】的次数）。",

  ["ol_ex__chengpu_chun"] = "醇",
  ["#ol_ex__chunlao-invoke"] = "醇醪：你可以将%arg张“醇”置入弃牌堆，视为 %dest 使用一张【酒】",
  ["#ol_ex__chunlao-prey"] = "醇醪：你可以获得至多两张“醇”",

  ["$ol_ex__chunlao1"] = "备下佳酿，以做庆功之用。",
  ["$ol_ex__chunlao2"] = "饮此壮行酒，当立先头功。",
}

chunlao:addEffect(fk.AfterCardsMove, {
  anim_type = "special",
  derived_piles = "ol_ex__chengpu_chun",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chunlao.name) then
      local cards = {}
      local room = player.room
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.moveReason == fk.ReasonDiscard and move.from and
            (move.from == player or move.from == player:getNextAlive() or move.from == player:getLastAlive()) then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).trueName == "slash" and table.contains(room.discard_pile, info.cardId) then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end
      cards = room.logic:moveCardsHoldingAreaCheck(cards)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:addToPile("ol_ex__chengpu_chun", event:getCostData(self).cards, true, chunlao.name, player)
  end,
})

chunlao:addEffect(fk.AskForPeaches, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chunlao.name) and target.dying and
      #player:getPile("ol_ex__chengpu_chun") > player:usedEffectTimes(self.name, Player.HistoryRound)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = math.max(player:usedEffectTimes(self.name, Player.HistoryRound), 1)
    local cards = room:askToCards(player, {
      min_num = n,
      max_num = n,
      include_equip = false,
      skill_name = chunlao.name,
      cancelable = true,
      pattern = ".|.|.|ol_ex__chengpu_chun|.|.",
      prompt = "#ol_ex__chunlao-invoke::"..target.id..":"..n
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {target}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self).cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, chunlao.name, nil, true, player)
    if not target.dead then
      local card = Fk:cloneCard("analeptic")
      card.skillName = chunlao.name
      if target:canUseTo(Fk:cloneCard("analeptic"), target) then
        room:useCard({
          card = Fk:cloneCard("analeptic"),
          from = target,
          tos = {target},
          extra_data = {
            analepticRecover = true
          },
        })
      end
    end
  end,
})

return chunlao