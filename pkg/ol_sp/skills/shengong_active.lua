local shengong_active = fk.CreateSkill{
  name = "shengong_active",
}

Fk:loadTranslationTable{
  ["shengong_active"] = "神工",
}

shengong_active:addEffect("active", {
  card_num = 1,
  target_num = 1,
  expand_pile = function (self, player)
    return player:getTableMark("shengong-tmp")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getTableMark("shengong-tmp"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and #selected_cards == 1 and to_select:canMoveCardIntoEquip(selected_cards[1], true)
  end,
})

return shengong_active
