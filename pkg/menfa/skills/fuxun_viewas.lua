local fuxun_viewas = fk.CreateSkill{
  name = "fuxun_viewas",
}

Fk:loadTranslationTable{
  ["fuxun_viewas"] = "抚循",
}

local U = require "packages/utility/utility"

fuxun_viewas:addEffect("viewas", {
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames("fuxun", all_names, nil, nil, {bypass_times = true})
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = "fuxun"
    return card
  end,
})

return fuxun_viewas
