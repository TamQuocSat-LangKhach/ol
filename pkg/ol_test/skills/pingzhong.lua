local pingzhong = fk.CreateSkill{
  name = "pingzhong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["pingzhong"] = "屏忠",
  [":pingzhong"] = "锁定技，你每回合使用的前X张牌可以额外指定至多X个目标；当你受到伤害后，你摸X张牌（X为没有手牌的角色数+1）。",

  ["#pingzhong-choose"] = "屏忠：你可以为此%arg额外指定%arg2个目标",
}

pingzhong:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(pingzhong.name) and #data:getExtraTargets() > 0 then
      local room = player.room
      local n = 1 + #table.filter(room.alive_players, function (p)
        return p:isKongcheng()
      end)
      local use_events = room.logic:getEventsOfScope(GameEvent.UseCard, n, function (e)
        return e.data.from == player
      end, Player.HistoryTurn)
      return table.contains(use_events, room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true))
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 1 + #table.filter(room.alive_players, function (p)
      return p:isKongcheng()
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = n,
      targets = data:getExtraTargets(),
      skill_name = pingzhong.name,
      prompt = "#pingzhong-choose:::"..data.card:toLogString()..":"..n,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
  end,
})

pingzhong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 1 + #table.filter(room.alive_players, function (p)
      return p:isKongcheng()
    end)
    player:drawCards(n, pingzhong.name)
  end,
})

return pingzhong