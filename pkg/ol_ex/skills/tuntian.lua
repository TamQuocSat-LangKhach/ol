local tuntian = fk.CreateSkill {
  name = "ol_ex__tuntian",
}

Fk:loadTranslationTable {
  ["ol_ex__tuntian"] = "屯田",
  [":ol_ex__tuntian"] = "当你于回合外失去牌后，或于回合内因弃置而失去【杀】后，你可以进行判定，若结果不为<font color='red'>♥</font>，"..
  "你将判定牌置于你的武将牌上，称为“田”；你计算与其他角色的距离-X（X为“田”的数量）。",

  ["ol_ex__dengai_field"] = "田",

  ["$ol_ex__tuntian1"] = "兵农一体，以屯养战。",
  ["$ol_ex__tuntian2"] = "垦田南山，志在西川。",
}

tuntian:addEffect(fk.AfterCardsMove, {
  derived_piles = "ol_ex__dengai_field",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tuntian.name) then
      if player.room.current == player then
        for _, move in ipairs(data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).trueName == "slash" then
                return true
              end
            end
          end
        end
      else
        for _, move in ipairs(data) do
          if move.from == player and (move.to ~= player or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
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
      reason = tuntian.name,
      pattern = ".|.|spade,club,diamond",
    }
    room:judge(judge)
  end,
})

tuntian:addEffect(fk.FinishJudge, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.card.suit ~= Card.Heart and data.reason == tuntian.name
      and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("ol_ex__dengai_field", data.card, true, tuntian.name)
  end,
})

tuntian:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(tuntian.name) then
      return -#from:getPile("ol_ex__dengai_field")
    end
  end,
})

return tuntian