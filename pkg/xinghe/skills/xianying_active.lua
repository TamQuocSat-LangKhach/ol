local xianying_active = fk.CreateSkill{
  name = "xianying_active",
}

Fk:loadTranslationTable{
  ["xianying_active"] = "贤膺",
}

xianying_active:addEffect("active", {
  target_num = 0,
  card_filter = function (self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  feasible = function (self, player, selected, selected_cards)
    return table.contains(self.available_nums, #selected_cards)
  end,
})

return xianying_active
