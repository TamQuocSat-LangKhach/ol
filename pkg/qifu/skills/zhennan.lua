local zhennan = fk.CreateSkill{
  name = "ol__zhennan",
}
Fk:loadTranslationTable{
  ["ol__zhennan"] = "镇南",
  [":ol__zhennan"] = "【南蛮入侵】对你无效。出牌阶段限一次，你可以将至多X张手牌当目标数为X的【南蛮入侵】使用（X为其他角色数）。",

  ["#ol__zhennan"] = "镇南：你可以将至多%arg张手牌当指定等量目标的【南蛮入侵】使用",

  ["$ol__zhennan1"] = "镇守南中，夫君无忧。",
  ["$ol__zhennan2"] = "与君携手，定平蛮夷。",
}

zhennan:addEffect("active", {
  anim_type = "offensive",
  prompt = function (self, player)
    return "#ol__zhennan:::"..#Fk:currentRoom().alive_players
  end,
  min_card_num = 1,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhennan.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
  return #selected < #Fk:currentRoom().alive_players - 1 and table.contains(player:getHandlyIds(), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local card = Fk:cloneCard("savage_assault")
    card:addSubcards(selected_cards)
    return #selected < #selected_cards and player:canUse(card) and not player:isProhibited(to_select, card)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    room:useVirtualCard("savage_assault", effect.cards, player, effect.tos, zhennan.name)
  end
})
zhennan:addEffect(fk.PreCardEffect, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhennan.name) and data.card.trueName == "savage_assault" and data.to == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data.nullified = true
  end,
})

return zhennan
