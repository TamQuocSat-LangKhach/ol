local skill = fk.CreateSkill {
  name = "qin_seal_viewas",
}

Fk:loadTranslationTable{
  ["qin_seal_viewas"] = "传国玉玺",
}

local U = require "packages/utility/utility"

skill:addEffect("viewas", {
  interaction = function(self, player)
    local all_choices = {"savage_assault", "archery_attack", "god_salvation", "amazing_grace"}
    local choices = player:getViewAsCardNames(skill.name, all_choices)
    return U.CardNameBox {choices = choices, all_choices = all_choices}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "#qin_seal_skill"
    return card
  end,
})

return skill
