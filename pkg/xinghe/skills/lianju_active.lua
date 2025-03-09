local lianju_active = fk.CreateSkill{
  name = "lianju_active",
}

Fk:loadTranslationTable{
  ["lianju_active"] = "联句",
}

lianju_active:addEffect("active", {
  min_card_num = 1,
  max_card_num = 2,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    local cards = self.expand_pile
    return #selected < 2 and type(cards) == "table" and table.contains(cards, to_select) and
      table.every(selected, function(id)
        return Fk:getCardById(to_select, true).color == Fk:getCardById(id, true).color
      end)
  end,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
})

return lianju_active
