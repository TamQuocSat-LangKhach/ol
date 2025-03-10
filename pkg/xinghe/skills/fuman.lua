local fuman = fk.CreateSkill{
  name = "ol__fuman",
}

Fk:loadTranslationTable{
  ["ol__fuman"] = "抚蛮",
  [":ol__fuman"] = "出牌阶段每名角色限一次，你可以将一张手牌交给一名其他角色，此牌视为【杀】直到离开其手牌区。当其使用此【杀】结算后，"..
  "你摸一张牌；若此【杀】造成过伤害，你改为摸两张牌。",

  ["#ol__fuman"] = "抚蛮：将一张手牌视为【杀】交给一名角色，当其使用此【杀】后你摸牌",
  ["@@ol__fuman-inhand"] = "抚蛮",

  ["$ol__fuman1"] = "国家兴亡，匹夫有责。",
  ["$ol__fuman2"] = "跟着我们丞相走，错不了！",
}

fuman:addEffect("active", {
  anim_type = "support",
  prompt = "#ol__fuman",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not table.contains(player:getTableMark("ol__fuman-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "ol__fuman-phase", target.id)
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, fuman.name, nil, false, player,
      {"@@ol__fuman-inhand", player.id})
  end,
})
fuman:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("@@ol__fuman-inhand") ~= 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})
fuman:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@@ol__fuman-inhand") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.ol__fuman = data.card:getMark("@@ol__fuman-inhand")
  end,
})
fuman:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.ol__fuman == player.id and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards((data.damageDealt) and 2 or 1, fuman.name)
  end,
})

return fuman
