local jiawei_viewas = fk.CreateSkill{
  name = "jiawei_viewas",
}

Fk:loadTranslationTable{
  ["jiawei_viewas"] = "假威",
}

jiawei_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("duel")
    card:addSubcards(cards)
    card.skillName = "jiawei"
    return card
  end,
})

return jiawei_viewas
