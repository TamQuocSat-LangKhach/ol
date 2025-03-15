local liyong = fk.CreateSkill{
  name = "liyongw",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["liyongw"] = "历勇",
  [":liyongw"] = "转换技，出牌阶段，阳：你可以将一张本回合你未使用过的花色的牌当【决斗】使用；阴：你可以从弃牌堆获得一张你本回合使用过的花色的牌，"..
  "令一名角色视为对你使用一张【决斗】。",

  ["#liyongw-yang"] = "历勇：将一张本回合未使用花色的牌当【决斗】使用",
  ["#liyongw-yin"] = "历勇：获得弃牌堆中一张本回合已使用花色的牌，选择一名角色视为对你使用【决斗】",
  ["@liyongw-turn"] = "历勇",

  ["$liyongw1"] = "今日，我虽死，却未辱武安之名！",
  ["$liyongw2"] = "我受文举恩义，今当以死报之！",
}

liyong:addEffect("active", {
  anim_type = "switch",
  card_num = 1,
  min_target_num = 1,
  prompt = function(self, player)
    return "#liyongw-"..player:getSwitchSkillState(liyong.name, false, true)
  end,
  expand_pile = function (self, player)
    if player:getSwitchSkillState(liyong.name, false) == fk.SwitchYang then
      return player:getHandlyIds(false)
    elseif player:getSwitchSkillState(liyong.name, false) == fk.SwitchYin then
      return table.filter(Fk:currentRoom().discard_pile, function (id)
        return table.contains(player:getTableMark("@liyongw-turn"), Fk:getCardById(id):getSuitString(true))
      end)
    end
  end,
  can_use = Util.TrueFunc,
  card_filter = function (self, player, to_select, selected)
    if #selected == 0 then
      if player:getSwitchSkillState(liyong.name, false) == fk.SwitchYang then
        local suit = Fk:getCardById(to_select):getSuitString(true)
        if suit == "log_nosuit" then return end
        local card = Fk:cloneCard("duel")
        card.skillName = liyong.name
        card:addSubcard(to_select)
        return player:canUse(card) and not table.contains(player:getTableMark("@liyongw-turn"), suit)
      elseif player:getSwitchSkillState(liyong.name, false) == fk.SwitchYin then
        return table.contains(Fk:currentRoom().discard_pile, to_select)
      end
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if player:getSwitchSkillState(liyong.name, false) == fk.SwitchYang and #selected_cards == 1 then
      local card = Fk:cloneCard("duel")
      card.skillName = liyong.name
      card:addSubcards(selected_cards)
      return card.skill:targetFilter(player, to_select, selected, {}, card)
    elseif player:getSwitchSkillState(liyong.name, false) == fk.SwitchYin then
      return #selected == 0 and to_select:canUseTo(Fk:cloneCard("duel"), player)
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if #selected_cards == 1 then
      if player:getSwitchSkillState(liyong.name, false) == fk.SwitchYang then
        local card = Fk:cloneCard("duel")
        card.skillName = liyong.name
        card:addSubcards(selected_cards)
        return card.skill:feasible(player, selected, {}, card)
      elseif player:getSwitchSkillState(liyong.name, false) == fk.SwitchYin then
        return #selected == 1
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if player:getSwitchSkillState(liyong.name, true) == fk.SwitchYang then
      room:sortByAction(effect.tos)
      room:useVirtualCard("duel", effect.cards, player, effect.tos, liyong.name)
    else
      room:moveCardTo(effect.cards, Card.PlayerHand, player, fk.ReasonJustMove, liyong.name, nil, true, player)
      local target = effect.tos[1]
      if not player.dead then
        room:useVirtualCard("duel", nil, target, player, liyong.name)
      end
    end
  end,
})
liyong:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(liyong.name, true) and
      player.phase == Player.Play and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@liyongw-turn", data.card:getSuitString(true))
  end,
})

liyong:addAcquireEffect(function (self, player, is_start)
  if player.room.current == player then
    local room = player.room
    local mark = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player and use.card.suit ~= Card.NoSuit then
        table.insertIfNeed(mark, use.card:getSuitString(true))
      end
    end, Player.HistoryTurn)
    if #mark > 0 then
      room:setPlayerMark(player, "@liyongw-turn", mark)
    end
  end
end)

return liyong
