local fenrui_active = fk.CreateSkill{
  name = "fenrui_active",
}

Fk:loadTranslationTable{
  ["fenrui_active"] = "奋锐",
}

fenrui_active:addEffect("active", {
  card_num = 1,
  target_num = 0,
  interaction = function(self, player)
    local choices = player.sealedSlots
    table.removeOne(choices, Player.JudgeSlot)
    return UI.ComboBox { choices = choices }
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
})

return fenrui_active
