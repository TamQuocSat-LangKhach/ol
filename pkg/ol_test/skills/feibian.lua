local feibian = fk.CreateSkill {
  name = "feibian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["feibian"] = "飞辩",
  [":feibian"] = "锁定技，游戏开始时，你的出牌时间改为15秒。当你于回合内使用一张牌后，或当其他角色对你使用一张牌后，使用者"..
  "随机弃置一张手牌且本轮出牌时间减1秒（最少为1秒）。每个回合结束时，本回合出牌超时的角色失去1点体力。",
}

feibian:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(feibian.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local banner = room:getBanner("Timeout") or {}
    banner[tostring(player.id)] = 15
    room:setBanner("Timeout", banner)
  end,
})

feibian:addEffect(fk.CardUseFinished, {
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(feibian.name) and not target.dead then
      if target == player then
        return player.room.current == player
      else
        return table.contains(data.tos, player)
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(target:getCardIds("h"), function (id)
      return not target:prohibitDiscard(id)
    end)
    if #cards > 0 then
      room:throwCard(table.random(cards), feibian.name, target, target)
    end
    if not target.dead then
      local banner = room:getBanner("Timeout") or {}
      local timeout = banner[tostring(target.id)] or room.timeout
      if timeout > 1 then
        banner[tostring(target.id)] = math.max(timeout - 1, 1)
        room:addPlayerMark(target, "feibian_timeout_change-round", 1)
      end
      room:setBanner("Timeout", banner)
    end
  end,
})

feibian:addEffect(fk.RoundEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return player:getMark("feibian_timeout_change-round") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local banner = room:getBanner("Timeout") or {}
    local timeout = banner[tostring(player.id)] or room.timeout
    banner[tostring(player.id)] = timeout + player:getMark("feibian_timeout_change-round")
    room:setBanner("Timeout", banner)
  end,
})

feibian:addEffect(fk.HandleAskForPlayCard, {
  can_refresh = function (self, event, target, player, data)
    return data.afterRequest and table.contains(data.overtimes, player)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "feibian-turn", 1)
  end,
})

feibian:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:getMark("feibian-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 1, feibian.name)
  end,
})

return feibian
