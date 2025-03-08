local xinggu_active = fk.CreateSkill{
  name = "xinggu_active",
}

Fk:loadTranslationTable{
  ["xinggu_active"] = "行贾",
}

xinggu_active:addEffect("active", {
  card_num = 1,
  target_num = 1,
  expand_pile = "xinggu",
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getPile("xinggu"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and #selected_cards == 1 and to_select ~= player and
      to_select:hasEmptyEquipSlot(Fk:getCardById(selected_cards[1]).sub_type)
  end,
})

return xinggu_active
