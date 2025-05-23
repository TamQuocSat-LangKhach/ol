local zelie_active = fk.CreateSkill {
  name = "zelie_active",
}

Fk:loadTranslationTable{
  ["zelie_active"] = "泽烈",
  ["zelie_draw"] = "摸牌后再摸一张牌",
  ["zelie_discard"] = "弃牌后再弃一张牌",
}

zelie_active:addEffect("active", {
  interaction = UI.ComboBox { choices = { "zelie_draw", "zelie_discard" }},
  card_num = 0,
  target_num = 1,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
})

return zelie_active
