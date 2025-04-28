
local xiewei = fk.CreateSkill {
  name = "xiewei",
}

Fk:loadTranslationTable{
  ["xiewei"] = "卸尾",
  [":xiewei"] = "你可以将两张手牌置于武将牌上（称为“饵”），视为使用一张【杀】或【闪】。",

  ["#xiewei"] = "卸尾：将两张手牌置为“饵”，视为使用【杀】或【闪】",
  ["xiewei_bait"] = "饵",

  ["$xiewei1"] = "",
  ["$xiewei2"] = "",
}

local U = require "packages/utility/utility"

xiewei:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = "#xiewei",
  derived_piles = "xiewei_bait",
  interaction = function(self, player)
    local all_names = {"slash", "jink"}
    local names = player:getViewAsCardNames(xiewei.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and table.contains(player:getCardIds("h"), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 or self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = xiewei.name
    self.cost_data = cards
    return card
  end,
  before_use = function (self, player, use)
    player:addToPile("xiewei_bait", self.cost_data, true, xiewei.name, player)
  end,
  enabled_at_response = function (self, player, response)
    return not response and player:getHandcardNum() > 1
  end,
})

return xiewei
