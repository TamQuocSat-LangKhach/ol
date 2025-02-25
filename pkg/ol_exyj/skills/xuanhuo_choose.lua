local this = fk.CreateSkill{
  name = "ol_ex__xuanhuo_choose",
}

this:addEffect('active', {
  mute = true,
  card_num = 2,
  target_num = 2,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    if #selected_cards == 2 then
      return #selected == 0 and to_select ~= player.id or #selected == 1
    end
  end,
})

return this
