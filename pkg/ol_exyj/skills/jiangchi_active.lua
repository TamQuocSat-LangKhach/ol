local jiangchi_active = fk.CreateSkill{
  name = "ol_ex__jiangchi_active",
}

Fk:loadTranslationTable{
  ["ol_ex__jiangchi_select"] = "将驰",
  ["ol_ex__jiangchi1"] = "摸一张牌，使用【杀】次数上限-1",
  ["ol_ex__jiangchi2"] = "重铸一张牌，使用【杀】次数上限+1",
}

jiangchi_active:addEffect("active", {
  min_card_num = 0,
  max_card_num = 1,
  target_num = 0,
  interaction = UI.ComboBox {choices = {"ol_ex__jiangchi1", "ol_ex__jiangchi2"}},
  card_filter = function (self, player, to_select, selected)
    return self.interaction.data == "ol_ex__jiangchi2" and #selected == 0
  end,
})

return jiangchi_active