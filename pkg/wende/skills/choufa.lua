local choufa = fk.CreateSkill{
  name = "choufa",
}

Fk:loadTranslationTable{
  ["choufa"] = "筹伐",
  [":choufa"] = "出牌阶段限一次，你可展示一名其他角色的一张手牌，其当前手牌中与此牌类别不同的牌均视为【杀】直到其回合结束。",

  ["#choufa"] = "筹伐：展示一名角色一张手牌，其手牌中不为此类别的牌均视为【杀】直到其回合结束",
  ["@@choufa-inhand"] = "筹伐",

  ["$choufa1"] = "秣马厉兵，筹伐不臣！",
  ["$choufa2"] = "枕戈待旦，秣马征平。",
}

choufa:addEffect("active", {
  anim_type = "control",
  prompt = "#choufa",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(choufa.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = choufa.name,
    })
    target:showCards(card)
    if not target.dead then
      for _, id in ipairs(target:getCardIds("h")) do
        if Fk:getCardById(id).type ~= Fk:getCardById(card).type then
          room:setCardMark(Fk:getCardById(id), "@@choufa-inhand", 1)
          Fk:filterCard(id, target)
        end
      end
    end
  end,
})
choufa:addEffect(fk.AfterTurnEnd, {
  can_refresh = function(self, event, target, player, data)
    return target == player and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    for _, id in ipairs(player:getCardIds("h")) do
      player.room:setCardMark(Fk:getCardById(id), "@@choufa-inhand", 0)
    end
    player:filterHandcards()
  end,
})
choufa:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("@@choufa-inhand") > 0
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

return choufa
