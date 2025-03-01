local siqi_active = fk.CreateSkill{
  name = "siqi_active",
}

Fk:loadTranslationTable{
  ["siqi_active"] = "思泣",
}

siqi_active:addEffect("active", {
  card_num = 1,
  expand_pile = function (self, player)
    return player:getTableMark("siqi-tmp")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getTableMark("siqi-tmp"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards == 0 or #selected > 0 then return false end
    local card = Fk:getCardById(selected_cards[1], true)
    return not player:isProhibited(to_select, card) and card.skill:modTargetFilter(player,to_select, {}, card, {bypass_times = true})
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards == 0 then return false end
    if #selected == 0 then
      local card = Fk:getCardById(selected_cards[1], true)
      return not player:isProhibited(player, card) and card.skill:modTargetFilter(player, player, {}, card, {bypass_times = true})
    end
    return true
  end,
})

return siqi_active
