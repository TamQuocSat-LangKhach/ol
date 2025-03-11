local xianbi = fk.CreateSkill{
  name = "xianbi",
}

Fk:loadTranslationTable{
  ["xianbi"] = "险诐",
  [":xianbi"] = "出牌阶段限一次，你可以将手牌调整至与一名角色装备区里的牌数相同，然后每因此弃置一张牌，你随机获得弃牌堆中另一张类型相同的牌。",

  ["#xianbi"] = "险诐：将手牌调整至一名角色装备区牌数，若因此弃牌则获得等量同类别牌",

  ["$xianbi1"] = "宦海如薄冰，求生逐富贵。",
  ["$xianbi2"] = "吾不欲为鱼肉，故为刀俎。",
}

xianbi:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#xianbi",
  min_card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xianbi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and not table.contains(player:getTableMark("zenrun"), to_select.id) then
      if player:getHandcardNum() > #to_select:getCardIds("e") then
        return #to_select:getCardIds("e") + #selected_cards == player:getHandcardNum()
      elseif player:getHandcardNum() < #to_select:getCardIds("e") then
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if #effect.cards > 0 then
      room:throwCard(effect.cards, xianbi.name, player, player)
      if player.dead then return end
      local ids, all_cards = {}, table.simpleClone(room.discard_pile)
      for _, id in ipairs(effect.cards) do
        local cards = table.filter(all_cards, function (c)
          return id ~= c and Fk:getCardById(id).type == Fk:getCardById(c).type
        end)
        if #cards > 0 then
          local c = table.random(cards)
          table.removeOne(all_cards, c)
          table.insert(ids, c)
        end
      end
      if #ids > 0 then
        room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, xianbi.name, nil, true, player)
      end
    else
      player:drawCards(#target:getCardIds("e") - player:getHandcardNum(), xianbi.name)
    end
  end,
})

return xianbi
