local xuanhuo_choose = fk.CreateSkill{
  name = "ol_ex__xuanhuo_choose",
}

xuanhuo_choose:addEffect("active", {
  card_num = 2,
  target_num = 2,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected_cards == 2 then
      return #selected == 0 and to_select ~= player or #selected == 1
    end
  end,
})

return xuanhuo_choose
