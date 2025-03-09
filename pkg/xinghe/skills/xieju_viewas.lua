local xieju_viewas = fk.CreateSkill{
  name = "xieju_viewas",
}

Fk:loadTranslationTable{
  ["xieju_viewas"] = "偕举",
}

xieju_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcard(cards[1])
    card.skillName = "xieju"
    return card
  end,
})

return xieju_viewas
