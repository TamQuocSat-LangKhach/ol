local qingxian_active = fk.CreateSkill{
  name = "ol__qingxian_active",
}

Fk:loadTranslationTable{
  ["ol__qingxian_active"] = "清弦",
}

qingxian_active:addEffect("active", {
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  interaction = function()
    return UI.ComboBox { choices = { "ol__qingxian_losehp", "ol__qingxian_recover" } }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if self.ol__qingxian then
      return false
    else
      return #selected == 0 and to_select ~= player
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if self.ol__qingxian then
      return #selected == 0
    else
      return #selected == 1
    end
  end,
})

return qingxian_active
