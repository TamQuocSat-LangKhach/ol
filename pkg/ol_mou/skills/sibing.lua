local sibing = fk.CreateSkill {
  name = "sibing",
}

Fk:loadTranslationTable{
  ["sibing"] = "司兵",
  [":sibing"] = "每回合限一次，当你使用伤害牌指定唯一目标时，你可以弃置任意张红色牌，目标需弃置等量红色手牌，否则其不能响应此牌；"..
  "以你为目标的伤害牌结算完成后，若未对你造成伤害，你可以弃置一张黑色牌，视为使用一张【杀】。",

  ["#sibing1-invoke"] = "司兵：你可以弃置任意张红色牌，令 %dest 需弃置等量红色手牌，否则其不能响应此牌",
  ["#sibing-discard"] = "司兵：你需弃置%arg张红色手牌，否则不能响应此%arg",
  ["#sibing2-invoke"] = "司兵：你可以弃置一张黑色牌，视为使用一张【杀】",
  ["#sibing-slash"] = "司兵：请视为使用【杀】",
}

sibing:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(sibing.name) and
      data.card.is_damage_card and data:isOnlyTarget(data.to) and not player.dead and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = sibing.name,
      pattern = ".|.|heart,diamond",
      prompt = "#sibing1-invoke::"..data.to.id,
      cancelable = true,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {data.to}, cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = #event:getCostData(self).cards
    room:throwCard(event:getCostData(self).cards, sibing.name, player, player)
    if data.to.dead then return end
    if #room:askToDiscard(data.to, {
      min_num = n,
      max_num = n,
      include_equip = false,
      skill_name = sibing.name,
      pattern = ".|.|heart,diamond",
      prompt = "#sibing-discard:::"..n..":"..data.card:toLogString(),
      cancelable = true,
    }) == 0 then
      data.disresponsive = true
    end
  end,
})

sibing:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(sibing.name) and table.contains(data.tos, player) and
      data.card.is_damage_card and not (data.damageDealt and data.damageDealt[player]) and
      not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = sibing.name,
      pattern = ".|.|spade,club",
      prompt = "#sibing2-invoke",
      cancelable = true,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, sibing.name, player, player)
    if player.dead or not player:canUse(Fk:cloneCard("slash"), {bypass_times = true}) then return end
    room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = sibing.name,
      prompt = "#sibing-slash",
      cancelable = false,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
    })
  end,
})

return sibing
