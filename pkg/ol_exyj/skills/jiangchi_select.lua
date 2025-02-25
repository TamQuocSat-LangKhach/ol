local this = fk.CreateSkill{
  name = "jiangchi_select",
}

this:addEffect("active", {
  target_num = 0,
  max_card_num = 1,
  min_card_num = 0,
  interaction = function()
    return UI.ComboBox {choices = {"ol_ex__jiangchi1", "ol_ex__jiangchi2"}}
  end,
  card_filter = function (self, player, to_select, selected)
    return (self.interaction or {}).data == "ol_ex__jiangchi2" and #selected == 0
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__jiangchi_select"] = "将驰",
  ["ol_ex__jiangchi1"] = "摸一张牌，次数上限-1",
  ["ol_ex__jiangchi2"] = "重铸一张牌，次数上限+1",
}

return this