local niluan_viewas = fk.CreateSkill{
  name = "ol__niluan_viewas",
}

Fk:loadTranslationTable{
  ["ol__niluan_viewas"] = "逆乱",
}

niluan_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function (self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = "ol__niluan"
    c:addSubcard(cards[1])
    return c
  end,
})

return niluan_viewas
