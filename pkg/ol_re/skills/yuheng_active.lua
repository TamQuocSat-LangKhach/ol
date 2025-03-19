local yuheng_active = fk.CreateSkill{
  name = "yuheng_active",
}

Fk:loadTranslationTable{
  ["yuheng_active"] = "驭衡",
}

yuheng_active:addEffect("active", {
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if not player:prohibitDiscard(to_select) and Fk:getCardById(to_select).suit ~= Card.NoSuit then
      if #selected == 0 then
        return true
      else
        return table.every(selected, function(id)
          return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id), true)
        end)
      end
    end
  end,
})

return yuheng_active
