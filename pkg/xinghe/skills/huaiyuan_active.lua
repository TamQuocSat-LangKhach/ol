local huaiyuan_active = fk.CreateSkill{
  name = "huaiyuan_active",
}

Fk:loadTranslationTable{
  ["huaiyuan_active"] = "怀远",
}

huaiyuan_active:addEffect("active", {
  interaction = UI.ComboBox {choices = {"huaiyuan_maxcards", "huaiyuan_attackrange", "draw1"}},
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
})

return huaiyuan_active
