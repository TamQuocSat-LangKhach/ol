local jiewan_viewas = fk.CreateSkill{
  name = "jiewan_viewas",
}

Fk:loadTranslationTable{
  ["jiewan_viewas"] = "解腕",
}

jiewan_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("snatch")
    card.skillName = "jiewan"
    card:addSubcard(cards[1])
    return card
  end,
})

return jiewan_viewas
