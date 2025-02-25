local this = fk.CreateSkill {
  name = "ol_ex__tuntian",
  derived_piles = "ol_ex__dengai_field",
}

this:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(this.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and (move.to ~= player.id or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              if (move.moveReason == fk.ReasonDiscard and Fk:getCardById(info.cardId).trueName == "slash") or
              player.phase == Player.NotActive then return true end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = this.name,
      pattern = ".|.|spade,club,diamond",
    }
    room:judge(judge)
  end,
})

this:addEffect(fk.FinishJudge, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.card.suit ~= Card.Heart and data.reason == this.name
      and player.room:getCardArea(data.card.id) == Card.Processing
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:addToPile("ol_ex__dengai_field", data.card, true, this.name)
  end,
})

this:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(this.name) then
      return -#from:getPile("ol_ex__dengai_field")
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__tuntian"] = "屯田",
  [":ol_ex__tuntian"] = "当你于回合外失去牌后，或于回合内因弃置而失去【杀】后，你可以进行判定，若结果不为<font color='red'>♥</font>，你将判定牌置于你的武将牌上，称为“田”；你计算与其他角色的距离-X（X为“田”的数量）。",
  
  ["ol_ex__dengai_field"] = "田",
  
  ["$ol_ex__tuntian1"] = "兵农一体，以屯养战。",
  ["$ol_ex__tuntian2"] = "垦田南山，志在西川。",
}

return this