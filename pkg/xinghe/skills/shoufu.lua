local shoufu = fk.CreateSkill{
  name = "shoufu",
}

Fk:loadTranslationTable{
  ["shoufu"] = "授符",
  [":shoufu"] = "出牌阶段限一次，你可以摸一张牌，然后将一张手牌置于一名没有“箓”的其他角色的武将牌上，称为“箓”；其不能使用和打出与“箓”同类别的牌。"..
  "该角色受到伤害后，或于弃牌阶段弃置至少两张与“箓”同类型的牌后，将“箓”置入弃牌堆。",

  ["#shoufu"] = "授符：摸一张牌，将一张手牌置为一名角色的“箓”，其不能使用打出此类别的牌",
  ["zhangling_lu"] = "箓",
  ["#shoufu-choose"] = "授符：将一张手牌置为一名角色的“箓”，其不能使用打出“箓”同类别的牌",

  ["$shoufu1"] = "得授符法，驱鬼灭害。",
  ["$shoufu2"] = "吾得法器，必斩万恶！",
}

shoufu:addEffect("active", {
  anim_type = "control",
  prompt = "#shoufu",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(shoufu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:drawCards(1, shoufu.name)
    if player:isKongcheng() or player.dead then return end
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return #p:getPile("zhangling_lu") == 0
    end)
    if #targets == 0 then return end
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      pattern = ".|.|.|hand",
      skill_name = shoufu.name,
      prompt = "#shoufu-choose",
      cancelable = false,
    })
    to[1]:addToPile("zhangling_lu", cards, true, shoufu.name, player)
  end,
})
shoufu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if #player:getPile("zhangling_lu") > 0 then
      return card and card.type == Fk:getCardById(player:getPile("zhangling_lu")[1]).type
    end
  end,
  prohibit_response = function(self, player, card)
    if #player:getPile("zhangling_lu") > 0 then
      return card and card.type == Fk:getCardById(player:getPile("zhangling_lu")[1]).type
    end
  end,
})
shoufu:addEffect(fk.Damaged, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile("zhangling_lu") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:moveCardTo(player:getPile("zhangling_lu"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile)
  end,
})
shoufu:addEffect(fk.AfterCardsMove, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if #player:getPile("zhangling_lu") > 0 and player.phase == Player.Discard then
      local n = 0
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).type == Fk:getCardById(player:getPile("zhangling_lu")[1]).type and
              (info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand) then
              n = n + 1
              if n == 2 then return true end
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:moveCardTo(player:getPile("zhangling_lu"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile)
  end,
})

return shoufu
