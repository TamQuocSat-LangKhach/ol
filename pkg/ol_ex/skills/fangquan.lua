local fangquan = fk.CreateSkill {
  name = "ol_ex__fangquan",
}

Fk:loadTranslationTable {
  ["ol_ex__fangquan"] = "放权",
  [":ol_ex__fangquan"] = "出牌阶段开始前，你可跳过此阶段，然后弃牌阶段开始时，你可弃置一张手牌并选择一名其他角色，其获得一个额外回合。",

  ["#ol_ex__fangquan-choose"] = "放权：弃置一张手牌，令一名角色获得一个额外回合",

  ["$ol_ex__fangquan1"] = "蜀汉有相父在，我可安心。",
  ["$ol_ex__fangquan2"] = "这些事情，你们安排就好。",
}

fangquan:addEffect(fk.EventPhaseChanging, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fangquan.name) and player == target and data.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    data.skipped = true
  end,
})

fangquan:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and
      player:usedEffectTimes(fangquan.name, Player.HistoryTurn) > 0 and
      not player.dead and not player:isKongcheng() and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|.|hand",
      skill_name = fangquan.name,
      prompt = "#ol_ex__fangquan-choose",
      cancelable = true,
      will_throw = true,
    })
    if #tos > 0 and #cards > 0 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, fangquan.name, player, player)
    local to = event:getCostData(self).tos[1]
    if not to.dead then
      to:gainAnExtraTurn(true, fangquan.name)
    end
  end,
})

return fangquan