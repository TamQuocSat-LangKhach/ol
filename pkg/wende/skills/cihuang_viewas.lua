local cihuang_viewas = fk.CreateSkill{
  name = "cihuang_viewas",
}

Fk:loadTranslationTable{
  ["cihuang_viewas"] = "雌黄",
}

local U = require "packages/utility/utility"

cihuang_viewas:addEffect("active", {
  handly_pile = true,
  interaction = function (self, player)
    local all_choices = player:getTableMark("cihuang_all_names")
    local choices = table.filter(all_choices, function (name)
      return not table.contains(player:getTableMark("cihuang-round"), name)
    end)
    return U.CardNameBox { choices = choices, all_choices = all_choices }
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected_cards == 1 then
      local card = Fk:cloneCard(self.interaction.data)
      card.skillName = "cihuang"
      card:addSubcard(selected_cards[1])
      if player:prohibitUse(card) then return end
      if #selected == 0 then
        return to_select == Fk:currentRoom().current and
          not player:isProhibited(to_select, card) and
          card.skill:modTargetFilter(player, to_select, {}, card, {bypass_distances = true, bypass_times = true})
      else
        return card.skill:targetFilter(player, to_select, selected, {}, card, {bypass_distances = true, bypass_times = true})
      end
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if #selected_cards == 1 then
      local card = Fk:cloneCard(self.interaction.data)
      card.skillName = "cihuang"
      card:addSubcard(selected_cards[1])
      return #selected >= card.skill:getMinTargetNum(player) and selected[1] == Fk:currentRoom().current
    end
  end,
})

return cihuang_viewas
