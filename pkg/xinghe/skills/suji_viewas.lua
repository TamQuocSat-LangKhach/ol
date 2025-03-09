local suji_viewas = fk.CreateSkill{
  name = "suji_viewas",
}

Fk:loadTranslationTable{
  ["suji_viewas"] = "肃疾",
}

suji_viewas:addEffect("viewas", {
  card_num = 1,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcard(cards[1])
    card.skillName = "suji"
    return card
  end,
})

return suji_viewas
