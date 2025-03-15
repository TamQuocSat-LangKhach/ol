local shenjun_viewas = fk.CreateSkill{
  name = "shenjun_viewas",
}

Fk:loadTranslationTable{
  ["shenjun_viewas"] = "神君",
}

local U = require "packages/utility/utility"

shenjun_viewas:addEffect("viewas", {
  interaction = function(self, player)
    local all_names = {}
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card:getMark("@@shenjun-inhand-phase") > 0 then
        table.insertIfNeed(all_names, card.name)
      end
    end
    local names = player:getViewAsCardNames("shenjun", all_names)
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected < #player:getTableMark("@$shenjun-phase")
  end,
  view_as = function(self, player, cards)
    if #cards ~= #player:getTableMark("@$shenjun-phase") or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = "shenjun"
    return card
  end,
})

return shenjun_viewas
