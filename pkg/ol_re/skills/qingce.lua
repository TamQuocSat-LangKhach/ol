local qingce = fk.CreateSkill {
  name = "ol__qingce",
}

Fk:loadTranslationTable{
  ["ol__qingce"] = "清侧",
  [":ol__qingce"] = "出牌阶段，你可以获得一张“荣”并弃置一张手牌，然后弃置场上的一张牌。",

  ["#ol__qingce"] = "清侧：获得一张“荣”并弃置一张手牌，然后弃置场上的一张牌",

  ["$ol__qingce1"] = "陛下身陷囹圄，臣唯勤王救之！",
  ["$ol__qingce2"] = "今，天不得时，地不得利，需谨慎用兵。",
}

qingce:addEffect("active", {
  anim_type = "control",
  card_num = 2,
  target_num = 1,
  prompt = "#ol__qingce",
  expand_pile = "$guanqiujian__glory",
  card_filter = function(self, player, to_select, selected)
    if #selected < 2 then
      if table.contains(player:getPile("$guanqiujian__glory"), to_select) then
        return #selected == 0 or not table.contains(player:getPile("$guanqiujian__glory"), selected[1])
      elseif table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select) then
        return #selected == 0 or not table.contains(player:getCardIds("h"), selected[1])
      end
    end
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #to_select:getCardIds("ej") > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local get = table.filter(effect.cards, function (id)
      return table.contains(player:getPile("$guanqiujian__glory"), id)
    end)
    local discard = table.filter(effect.cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    local moves = {}
    table.insert(moves, {
      ids = discard,
      from = player,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonDiscard,
      skillName = qingce.name,
      proposer = player,
    })
    table.insert(moves, {
      ids = get,
      from = player,
      to = player,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      skillName = qingce.name,
      proposer = player,
    })
    room:moveCards(table.unpack(moves))
    if player.dead or target.dead then return end
    if #target:getCardIds("ej") > 0 then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "ej",
        skill_name = qingce.name,
      })
      room:throwCard(card, qingce.name, target, player)
    end
  end,
})

return qingce
