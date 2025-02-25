local U = require("packages.utility.utility")

local this = fk.CreateSkill{
  name = "ol_ex__chunlao",
  anim_type = "support",
  derived_piles = "ol_ex__chengpu_chun",
}

this:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(this.name) then
      local cards = {}
      local room = player.room
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.moveReason == fk.ReasonDiscard and move.from and
            (move.from == player.id or move.from == player:getNextAlive().id or move.from == player:getLastAlive().id) then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).trueName == "slash" and table.contains(room.discard_pile, info.cardId) then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end
      cards = U.moveCardsHoldingAreaCheck(room, cards)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:addToPile("ol_ex__chengpu_chun", self.cost_data, true, this.name, player.id)
  end,
})

this:addEffect(fk.AskForPeaches, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(this.name) then
      return target.dying and #player:getPile("ol_ex__chengpu_chun") > player:getMark("ol_ex__chunlao-round")
    end
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:getMark("ol_ex__chunlao-round") + 1
    local cards = player.room:askToCards(player, { min_num = n, max_num = n, include_equip = false, skill_name = this.name,
      cancelable = true, pattern = ".|.|.|ol_ex__chengpu_chun|.|.", prompt = "#ol_ex__chunlao-invoke::"..target.id..":"..n
    })
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      player:addToPile("ol_ex__chengpu_chun", self.cost_data, true, this.name, player.id)
    elseif event == fk.AskForPeaches then
      room:addPlayerMark(player, "ol_ex__chunlao-round", 1)
      room:moveCardTo(self.cost_data, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, this.name, nil, true, player.id)
      if not target.dead then
        local card = Fk:cloneCard("analeptic")
        card.skillName = this.name
        if not target:prohibitUse(Fk:cloneCard("analeptic")) and not target:isProhibited(target, Fk:cloneCard("analeptic")) then
          room:useCard({
            card = Fk:cloneCard("analeptic"),
            from = target.id,
            tos = {target},
            extra_data = {
              analepticRecover = true
            },
          })
        end
      end
    end
  end,
})

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

return this