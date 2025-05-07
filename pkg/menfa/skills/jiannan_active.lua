local jiannan_active = fk.CreateSkill{
  name = "jiannan_active",
}

Fk:loadTranslationTable{
  ["jiannan_active"] = "间难",
}

jiannan_active:addEffect("active", {
  interaction = function(self, player)
    local choices, all_choices = {}, {}
    for i = 1, 4 do
      table.insert(all_choices, "jiannan".. i)
      if not table.contains(player:getTableMark("jiannan-turn"), i) then
        table.insert(choices, "jiannan".. i)
      end
    end
    return UI.ComboBox { choices = choices, all_choices = all_choices, }
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
})

return jiannan_active
