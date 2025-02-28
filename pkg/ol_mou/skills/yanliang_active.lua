local yanliangy_active = fk.CreateSkill{
  name = "yanliangy&",
}

Fk:loadTranslationTable{
  ["yanliangy&"] = "厌粱",
  [":yanliangy&"] = "出牌阶段限一次，你可以交给谋袁术一张装备牌，视为使用一张【酒】。",

  ["#yanliangy&"] = "厌粱：你可以交给谋袁术一张装备牌，视为使用一张【酒】",
}

yanliangy_active:addEffect("active", {
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  prompt = "#yanliangy&",
  can_use = function(self, player)
    return player.kingdom == "qun" and player:usedSkillTimes(yanliangy_active.name, Player.HistoryPhase) == 0 and
      player:canUse(Fk:cloneCard("analeptic"))
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0 and to_select:hasSkill("yanliangy")
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, "yanliangy", nil, true, player)
    room:useVirtualCard("analeptic", nil, player, player, "yanliangy")
  end,
})

return yanliangy_active
