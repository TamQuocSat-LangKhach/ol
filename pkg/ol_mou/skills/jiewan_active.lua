local jiewan_active = fk.CreateSkill{
  name = "jiewan_active",
}

Fk:loadTranslationTable{
  ["jiewan_active"] = "解腕",
}

jiewan_active:addEffect("active", {
  min_card_num = 0,
  max_card_num = 2,
  target_num = 0,
  expand_pile = "dengai_grain",
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and table.contains(player:getPile("dengai_grain"), to_select)
  end,
  feasible = function (self, player, selected, selected_cards)
    return #selected_cards == 0 or #selected_cards == 2
  end,
})

return jiewan_active
