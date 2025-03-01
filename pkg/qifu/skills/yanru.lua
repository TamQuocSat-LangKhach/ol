local yanru = fk.CreateSkill{
  name = "yanru",
}

Fk:loadTranslationTable{
  ["yanru"] = "晏如",
  [":yanru"] = "出牌阶段各限一次，若你的手牌数为：奇数，你可以摸三张牌，然后弃置至少半数手牌；偶数，你可以弃置至少半数手牌，然后摸三张牌。",

  ["#yanru1"] = "晏如：你可以摸三张牌，然后弃置至少半数手牌",
  ["#yanru2"] = "晏如：你可以弃置至少%arg张手牌，然后摸三张牌",
  ["#yanru-discard"] = "晏如：请弃置至少%arg张手牌",

  ["$yanru1"] = "国有宁日，民有丰年，大同也。",
  ["$yanru2"] = "及臻厥成，天下晏如也。",
}

yanru:addEffect("active", {
  anim_type = "drawcard",
  min_card_num = 0,
  target_num = 0,
  prompt = function (self, player)
    if player:getHandcardNum() % 2 == 0 then
      return "#yanru2:::"..(player:getHandcardNum() // 2)
    else
      return "#yanru1"
    end
  end,
  can_use = function(self, player)
    if player:getHandcardNum() % 2 == 0 then
      return not player:isKongcheng() and player:getMark("yanru2-phase") == 0
    else
      return player:getMark("yanru1-phase") == 0
    end
  end,
  card_filter = function (self, player, to_select, selected)
    if player:getHandcardNum() % 2 == 0 then
      return table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  target_filter = Util.FalseFunc,
  feasible = function (self, player, selected, selected_cards)
    if player:getHandcardNum() % 2 == 0 then
      return #selected_cards >= (player:getHandcardNum() // 2)
    else
      return true
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if player:getHandcardNum() % 2 == 0 then
      room:setPlayerMark(player, "yanru2-phase", 1)
      room:throwCard(effect.cards, yanru.name, player, player)
      if not player.dead then
        player:drawCards(3, yanru.name)
      end
    else
      room:setPlayerMark(player, "yanru1-phase", 1)
      player:drawCards(3, yanru.name)
      if not player.dead and not player:isKongcheng() then
        room:askToDiscard(player, {
          min_num = player:getHandcardNum() // 2,
          max_num = 999,
          include_equip = false,
          skill_name = yanru.name,
          prompt = "#yanru-discard:::"..(player:getHandcardNum() // 2),
          cancelable = false,
        })
      end
    end
  end,
})

return yanru
