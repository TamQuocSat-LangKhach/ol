local dianzhan = fk.CreateSkill{
  name = "dianzhan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dianzhan"] = "点盏",
  [":dianzhan"] = "锁定技，当你每轮首次使用一种花色的牌后，你令此牌唯一目标横置并重铸此花色的所有手牌，若均执行，你摸一张牌。",

  ["@dianzhan-round"] = "点盏",

  ["$dianzhan1"] = "此灯如我，独向光明。",
  ["$dianzhan2"] = "此间皆暗，唯灯瞩明。",
}

dianzhan:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local suits = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        table.insertIfNeed(suits, use.card:getSuitString(true))
      end
    end, Player.HistoryRound)
    table.removeOne(suits, "log_nosuit")
    if #suits > 0 then
      room:setPlayerMark(player, "@dianzhan-round", suits)
    end
  end
end)
dianzhan:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@dianzhan-round", 0)
end)

dianzhan:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(dianzhan.name) and data.card.suit ~= Card.NoSuit and
      #player:getTableMark("@dianzhan-round") < 4 then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == player and use.card:compareSuitWith(data.card)
      end, Player.HistoryRound)
      if #use_events == 1 then
        player.room:addTableMarkIfNeed(player, "@dianzhan-round", data.card:getSuitString(true))
        return use_events[1].data == data
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dianzhan1, dianzhan2 = false, false
    if #data.tos == 1 and not data.tos[1].dead and not data.tos[1].chained then
      dianzhan1 = true
      data.tos[1]:setChainState(true)
      if player.dead then return end
    end
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):compareSuitWith(data.card)
    end)
    if #cards > 0 then
      dianzhan2 = true
      room:recastCard(cards, player, dianzhan.name)
      if player.dead then return end
    end
    if dianzhan1 and dianzhan2 then
      player:drawCards(1, dianzhan.name)
    end
  end,
})
dianzhan:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(dianzhan.name, true) and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@dianzhan-round", data.card:getSuitString(true))
  end,
})

return dianzhan
