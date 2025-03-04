local chuming_viewas = fk.CreateSkill{
  name = "chuming_viewas",
}

Fk:loadTranslationTable{
  ["chuming_viewas"] = "畜鸣",
}

local U = require "packages/utility/utility"

chuming_viewas:addEffect("active", {
  interaction = function (self, player)
    return U.CardNameBox { choices = {"dismantlement", "collateral"} }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected == 0 then
      return to_select.id == self.chuming_info[1]
    elseif #selected == 1 and self.interaction.data == "collateral" then
      local card = Fk:cloneCard("collateral")
      card.skillName = "chuming"
      return card.skill:targetFilter(player, to_select, {Fk:currentRoom():getPlayerById(self.chuming_info[1])}, {}, card)
    end
  end,
})

return chuming_viewas
