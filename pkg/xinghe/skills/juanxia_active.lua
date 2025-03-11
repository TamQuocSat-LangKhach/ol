local juanxia_active = fk.CreateSkill{
  name = "juanxia_active",
}

Fk:loadTranslationTable{
  ["juanxia_active"] = "狷狭",
}

juanxia_active:addEffect("active", {
  expand_pile = function(self, player)
    return self.juanxia_names
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local mark = self.juanxia_names
    if table.contains(mark, to_select) then
      local name = Fk:getCardById(to_select).name
      local card = Fk:cloneCard(name)
      card.skillName = "juanxia"
      if player:canUse(card) and not player:prohibitUse(card) then
        local target = self.juanxia_target
        return target == nil or (card.skill:targetFilter(player, Fk:currentRoom():getPlayerById(target), {}, {}, card, nil) and
        not player:isProhibited(Fk:currentRoom():getPlayerById(target), card))
      end
    end
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected_cards == 0 then return false end
    local card = Fk:cloneCard(Fk:getCardById(selected_cards[1]).name)
    card.skillName = "juanxia"
    local selected_copy = table.simpleClone(selected)
    local target = self.juanxia_target
    if target ~= nil then
      table.insert(selected_copy, 1, Fk:currentRoom():getPlayerById(target))
    end
    if #selected_copy == 0 then
      return to_select ~= player and card.skill:targetFilter(player, to_select, {}, {}, card, nil) and
        not player:isProhibited(to_select, card)
    else
      if card.skill:getMinTargetNum(player) == 1 then return false end
      return card.skill:targetFilter(player, to_select, selected_copy, {}, card, nil)
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards == 0 then return false end
    local to_use = Fk:cloneCard(Fk:getCardById(selected_cards[1]).name)
    to_use.skillName = "juanxia"
    local selected_copy = table.simpleClone(selected)
    local target = self.juanxia_target
    if target ~= nil then
      table.insert(selected_copy, 1, Fk:currentRoom():getPlayerById(target))
    end
    return to_use.skill:feasible(player, selected_copy, {}, to_use)
  end,
})

return juanxia_active
