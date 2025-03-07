local moushi = fk.CreateSkill{
  name = "moushi",
}

Fk:loadTranslationTable{
  ["moushi"] = "谋识",
  [":moushi"] = "出牌阶段限一次，你可以将一张手牌交给一名其他角色。若如此做，当该角色于其下个出牌阶段对每名角色第一次造成伤害后，你摸一张牌。",

  ["#moushi"] = "谋识：将一张手牌交给一名角色，其下个出牌阶段对每名角色第一次造成伤害后你摸一张牌",

  ["$moushi1"] = "官渡决战，袁公必胜而曹氏必败。",
  ["$moushi2"] = "吾既辅佐袁公，定不会使其覆巢。",
}

moushi:addEffect("active", {
  anim_type = "support",
  prompt = "#moushi",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(moushi.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, moushi.name, nil, false, player)
    if not player.dead and not target.dead then
      room:addTableMarkIfNeed(target, "moushi_record", player.id)
    end
  end,
})
moushi:addEffect(fk.Damage, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target and player:getMark("moushi_record-phase") == target.id and
      not table.contains(player:getTableMark("moushi_draw-phase"), data.to.id)
  end,
  on_use = function (self, event, target, player, data)
    player.room:addTableMark(player, "moushi_draw-phase", data.to.id)
    player:drawCards(1, moushi.name)
  end,
})
moushi:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("moushi_record") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getMark("moushi_record")) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:setPlayerMark(p, "moushi_record-phase", player.id)
      end
    end
    room:setPlayerMark(player, "moushi_record", 0)
  end,
})

return moushi
