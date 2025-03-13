local juejue = fk.CreateSkill{
  name = "juejuew",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["juejuew"] = "决绝",
  [":juejuew"] = "锁定技，当你于回合内首次使用所有手牌指定其他角色为唯一目标时，令其弃置X张牌（X为本回合你使用牌指定其为目标的次数）。",

  ["$juejuew1"] = "",
  ["$juejuew2"] = "",
}

juejue:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(juejue.name) and
      player.room.current == player and
      #data.use.tos == 1 and data.to ~= player and
      data.extra_data and data.extra_data.juejue == player and
      not data.to.dead and not data.to:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {data.to}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
      local use = e.data
      return use.from == player and table.contains(use.tos, data.to)
    end, Player.HistoryTurn)
    room:askToDiscard(data.to, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = juejue.name,
      cancelable = false,
    })
  end,
})
juejue:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(juejue.name, true) and
      player.room.current == player and player:getMark("juejuew-turn") == 0 and
      #data.tos == 1 and data.tos[1] ~= player and
      table.every(player:getCardIds("h"), function (id)
        return table.contains(Card:getIdList(data.card), id)
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "juejuew-turn", 1)
    data.extra_data = data.extra_data or {}
    data.extra_data.juejue = player
  end,
})

return juejue
