local diaodu = fk.CreateSkill{
  name = "ol__diaodu",
}

Fk:loadTranslationTable{
  ["ol__diaodu"] = "调度",
  [":ol__diaodu"] = "当每回合首次与你势力相同的角色使用装备牌时，其可以摸一张牌。出牌阶段开始时，你可以获得与你势力相同的一名角色"..
  "装备区里的一张牌，然后你可将此牌交给另一名角色。",

  ["#ol__diaodu-invoke"] = "调度：你可摸一张牌",
  ["#ol__diaodu-choose"] = "调度：你可获得与你势力相同的一名角色装备区里的一张牌，然后交给另一名角色",
  ["#ol__diaodu-give"] = "调度：你可以将%arg交给另一名角色",

  ["$ol__diaodu1"] = "开源节流，作法于凉。",
  ["$ol__diaodu2"] = "调度征求，省刑薄敛。",
}

diaodu:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(diaodu.name) and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      if target.kingdom == player.kingdom and data.card.type == Card.TypeEquip and not target.dead then
        local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data
          return use.card.type == Card.TypeEquip and use.from.kingdom == player.kingdom
        end, Player.HistoryTurn)
        return #use_events == 1 and use_events[1].data == data
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = diaodu.name,
      prompt = "#ol__diaodu-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    target:drawCards(1, diaodu.name)
  end,
})
diaodu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(diaodu.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p)
        return p.kingdom == player.kingdom and #p:getCardIds("e") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p.kingdom == player.kingdom and #p:getCardIds("e") > 0
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = diaodu.name,
      prompt = "#ol__diaodu-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "e",
      skill_name = diaodu.name,
    })
    room:obtainCard(player, id, true, fk.ReasonPrey, player, diaodu.name)
    if not table.contains(player:getCardIds("h"), id) or player.dead then return end
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and p ~= to
    end)
    if #targets == 0 then return end
    to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = diaodu.name,
      prompt = "#ol__diaodu-give:::"..Fk:getCardById(id):toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      room:moveCardTo(id, Card.PlayerHand, to[1], fk.ReasonGive, diaodu.name, nil, true, player)
    end
  end,
})

return diaodu
