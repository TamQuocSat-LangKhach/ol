local xufa_viewas = fk.CreateSkill{
  name = "xufa_viewas",
}

Fk:loadTranslationTable{
  ["xufa_viewas"] = "蓄发",
}

local U = require "packages/utility/utility"

xufa_viewas:addEffect("viewas", {
  interaction = function(self, player)
    return U.CardNameBox { choices = player:getTableMark("xufa_tricks") }
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = "xufa"
    return card
  end,
})

return xufa_viewas
