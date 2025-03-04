local qingleng_viewas = fk.CreateSkill{
  name = "qingleng_viewas",
}

Fk:loadTranslationTable{
  ["qingleng_viewas"] = "清冷",
}

qingleng_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function (self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("ice__slash")
    c.skillName = "qingleng"
    c:addSubcard(cards[1])
    return c
  end,
})

return qingleng_viewas
