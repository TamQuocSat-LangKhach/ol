local yangji = fk.CreateSkill{
  name = "yangji",
}

Fk:loadTranslationTable{
  ["yangji"] = "佯疾",
  [":yangji"] = "准备阶段，或当你体力值变化过的回合结束时，你可以展示所有手牌，然后依次使用其中的黑色牌，直到无法使用或造成伤害。"..
  "然后若使用的最后一张牌为♠，你将之当【乐不思蜀】置于当前回合角色的判定区。",

  ["#yangji-use"] = "佯疾：请使用其中的黑色牌",

  ["$yangji1"] = "",
  ["$yangji2"] = "",
}

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(player:getCardIds("h"))
    player:showCards(cards)
    local last
    while not player.dead do
      cards = table.filter(cards, function (id)
        return table.contains(player:getCardIds("h"), id) and Fk:getCardById(id).color == Card.Black and
          player:canUse(Fk:getCardById(id), {bypass_times = true})
      end)
      if #cards == 0 then break end
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = yangji.name,
        prompt = "#yangji-use",
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
        cancelable = false,
        skip = true,
      })
      if use then
        table.removeOne(cards, use.card.id)
        last = use.card.id
        room:useCard(use)
        if use.damageDealt then
          break
        end
      else
        break
      end
    end
    if last and Fk:getCardById(last).suit == Card.Spade and
      table.contains({Card.DiscardPile, Card.PlayerEquip}, room:getCardArea(last)) and
      not room.current.dead and not table.contains(room.current.sealedSlots, Player.JudgeSlot) and
      not room.current:hasDelayedTrick("indulgence") then
      local card = Fk:cloneCard("indulgence")
      card:addSubcard(last)
      room.current:addVirtualEquip(card)
      room:moveCardTo(card, Player.Judge, room.current, fk.ReasonJustMove, yangji.name)
    end
  end,
}

yangji:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yangji.name) and player.phase == Player.Start and
      not player:isKongcheng()
  end,
  on_use = spec.on_use,
})

yangji:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yangji.name) and not player:isKongcheng() and
      #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        return e.data.who == player
      end, Player.HistoryTurn) > 0
  end,
  on_use = spec.on_use,
})

return yangji