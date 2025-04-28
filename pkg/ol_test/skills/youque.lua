local youque = fk.CreateSkill({
  name = "youque",
})

Fk:loadTranslationTable{
  ["youque"] = "诱阙",
  [":youque"] = "出牌阶段，你可以用点数最小的“饵”拼点。没赢的角色弃置点数大于其拼点牌的所有手牌，视为对赢的角色使用一张【杀】。"..
  "此【杀】造成伤害后，你摸两张牌，然后若“饵”的花色均不为♠，此技能此阶段失效。",

  ["#youque"] = "诱阙：用点数最小的“饵”与一名角色拼点，没赢的角色弃置手牌并视为对赢者使用【杀】",

  ["$youque1"] = "",
  ["$youque2"] = "",
}

youque:addEffect("active", {
  anim_type = "offensive",
  prompt = "#youque",
  card_num = 1,
  target_num = 1,
  expand_pile = "xiewei_bait",
  can_use = function(self, player)
    return #player:getPile("xiewei_bait") > 0
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getPile("xiewei_bait"), to_select) and
      table.every(player:getPile("xiewei_bait"), function (id)
        return Fk:getCardById(id).number >= Fk:getCardById(to_select).number
      end)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:canPindian(to_select, true)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, youque.name, Fk:getCardById(effect.cards[1]))
    local winner = pindian.results[target].winner
    if winner ~= player and not player.dead and pindian.fromCard then
      local cards = table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).number > pindian.fromCard.number and not player:prohibitDiscard(id)
      end)
      room:throwCard(cards, youque.name, player, player)
    end
    if winner ~= target and not target.dead and pindian.results[target].toCard then
      local cards = table.filter(target:getCardIds("h"), function (id)
        return Fk:getCardById(id).number > pindian.results[target].toCard.number and not target:prohibitDiscard(id)
      end)
      room:throwCard(cards, youque.name, target, target)
    end
    if winner == nil or winner.dead then return end
    local from = winner == player and target or player
    local use = room:useVirtualCard("slash", nil, from, winner, youque.name, true)
    if use and use.damageDealt and not player.dead then
      player:drawCards(2, youque.name)
      if not player.dead and
        table.every(player:getPile("xiewei_bait"), function (id)
          return Fk:getCardById(id).suit ~= Card.Spade
        end) then
        room:invalidateSkill(player, youque.name, "-phase")
      end
    end
  end,
})

return youque
