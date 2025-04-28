local juetu_active = fk.CreateSkill {
  name = "juetu_active",
}

Fk:loadTranslationTable{
  ["juetu_active"] = "绝途",
}

juetu_active:addEffect("active", {
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if table.contains(player:getCardIds("h"), to_select) and
      Fk:getCardById(to_select).suit ~= Card.NoSuit then
      if #selected == 0 then
        return true
      else
        return table.every(selected, function(id)
          return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id), true)
        end)
      end
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    local suits = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    table.removeOne(suits, Card.NoSuit)
    return #selected_cards == #suits
  end,
})

return juetu_active
