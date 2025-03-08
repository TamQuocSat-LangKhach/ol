local luochong_active = fk.CreateSkill{
  name = "luochong_active",
}

Fk:loadTranslationTable{
  ["luochong_active"] = "落宠",
}

luochong_active:addEffect("active", {
  interaction = function (self, player)
    local all_choices = table.filter({1, 2, 3, 4}, function (n)
      return not table.contains(player:getTableMark("luochong_removed"), n)
    end)
    local choices = table.filter(all_choices, function (n)
      return not table.contains(player:getTableMark("luochong_used-round"), n)
    end)
    all_choices = table.map(all_choices, function (n)
      return "luochong"..n
    end)
    choices = table.map(choices, function (n)
      return "luochong"..n
    end)
    return UI.ComboBox{ choices = choices, all_choices = all_choices }
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected == 0 and not table.contains(player:getTableMark("luochong_targets-round"), to_select.id) then
      if self.interaction.data == "luochong1" then
        return to_select:isWounded()
      elseif self.interaction.data == "luochong3" then
        return not to_select:isNude()
      else
        return true
      end
    end
  end,
})

return luochong_active
