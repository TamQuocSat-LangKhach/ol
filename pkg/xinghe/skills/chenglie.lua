local chenglie = fk.CreateSkill{
  name = "chenglie",
}

Fk:loadTranslationTable{
  ["chenglie"] = "骋烈",
  [":chenglie"] = "你使用【杀】可以多指定至多两个目标，然后展示牌堆顶与目标数等量张牌，秘密将一张手牌与其中一张牌交换，将之分别暗置于"..
  "目标角色武将牌上直到此【杀】结算结束，其中“骋烈”牌为红色的角色若：响应了此【杀】，其交给你一张牌；未响应此【杀】，其回复1点体力。",

  ["#chenglie-choose"] = "骋烈：你可以为%arg多指定1-2个目标，并执行后续效果",
  ["#chenglie-exchange"] = "骋烈：你可以用一张手牌交换其中一张牌",
  ["chenglie_active"] = "骋烈",
  ["#chenglie"] = "骋烈",
  ["#chenglie-give"] = "骋烈：将这些牌置于目标角色武将牌上直到【杀】结算结束",
  ["#chenglie-card"] = "骋烈：你需交给 %src 一张牌",
  ["$chenglie"] = "骋烈",

  ["$chenglie1"] = "铁蹄踏南北，烈马惊黄沙！",
  ["$chenglie2"] = "策马逐金雕，跨鞍寻天狼！",
}

Fk:addPoxiMethod{
  name = "chenglie",
  prompt = "#chenglie-exchange",
  card_filter = function(to_select, selected, data)
    if #selected < 2 then
      if #selected == 0 then
        return true
      else
        if table.contains(data[1][2], selected[1]) then
          return table.contains(data[2][2], to_select)
        else
          return table.contains(data[1][2], to_select)
        end
      end
    end
  end,
  feasible = function(selected)
    return #selected == 2
  end,
}

chenglie:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chenglie.name) and data.card.trueName == "slash" and
      #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 2,
      targets = data:getExtraTargets(),
      skill_name = chenglie.name,
      prompt = "#chenglie-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.chenglie = {}
    data.extra_data.chenglie.from = player

    local ids = room:getNCards(#data.tos)
    --FIXME:被拿走的牌会从处理区消失(*꒦ິ⌓꒦ີ*)
    --room:moveCardTo(ids, Card.Processing, player, fk.ReasonJustMove, chenglie.name, nil, true, player)
    player:showCards(ids)

    local results = room:askToPoxi(player, {
      poxi_type = "chenglie",
      data = {
        { "Top", ids },
        { "$Hand", player:getCardIds("h") },
      },
      cancelable = true,
    })
    if #results > 0 then
      local id1, id2 = results[1], results[2]
      if table.contains(player:getCardIds("h"), results[2]) then
        id1, id2 = results[2], results[1]
      end
      local move1 = {
        ids = {id1},
        from = player,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        skillName = chenglie.name,
        moveVisible = false,
      }
      local move2 = {
        ids = {id2},
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        skillName = chenglie.name,
        moveVisible = false,
      }
      table.insert(ids, id1)
      table.removeOne(ids, id2)
      room:moveCards(move1, move2)
      if player.dead then
        room:moveCardTo(ids, Card.DiscardPile, nil, fk.ReasonJustMove)
        return
      end
    end
    room:delay(2000)   --一定要delay到展示的牌从处理区消失，避免yiji过程中贴给牌的mark出现在处理区的牌上！
    local targets = table.filter(data.tos, function (p)
      return not p.dead
    end)
    if #targets == 0 then
      room:moveCardTo(ids, Card.DiscardPile, nil, fk.ReasonJustMove)
      return
    end
    room:sortByAction(targets)

    local result = room:askToYiji(player, {
      cards = ids,
      targets = targets,
      skill_name = chenglie.name,
      min_num = #targets,
      max_num = #targets,
      prompt = "#chenglie-give",
      cancelable = false,
      expand_pile = ids,
      skip = true,
    })
    data.extra_data.chenglie.results = result
    local moves = {}
    for _, p in ipairs(targets) do
      table.insert(moves, {
        ids = result[p.id],
        to = p,
        toArea = Card.PlayerSpecial,
        moveReason = fk.ReasonJustMove,
        skillName = chenglie.name,
        specialName = "$chenglie",
        proposer = player,
        moveVisible = false,
      })
    end
    room:moveCards(table.unpack(moves))
  end,
})
chenglie:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.chenglie and data.extra_data.chenglie.from == player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local results = data.extra_data.chenglie.results
    local targets = table.simpleClone(data.tos)
    room:sortByAction(targets)

    local resp_players = {}
    if data.cardsResponded then
      local use_events = room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      for i = #use_events, 1, -1 do
        local e = use_events[i]
        local use = e.data
        if e.data == data then break end
        if table.contains(data.cardsResponded, use.card) then
          table.insert(resp_players, use.from)
        end
      end
    end

    for _, to in ipairs(targets) do
      if not to.dead then
        local id = results[to.id][1]
        local red = Fk:getCardById(id).color == Card.Red
        if table.contains(to:getPile("$chenglie"), id) then
          room:moveCardTo(id, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, chenglie.name)
        end
        if red and not to.dead then
          if table.contains(resp_players, to) then
            if not (to:isNude() or player.dead) then
              local card = room:askToCards(to, {
                min_num = 1,
                max_num = 1,
                include_equip = true,
                skill_name = chenglie.name,
                prompt = "#chenglie-card:"..player.id,
                cancelable = false,
              })
              room:obtainCard(player, card, false, fk.ReasonGive, to, chenglie.name)
            end
          elseif to:isWounded() then
            room:recover{
              who = to,
              num = 1,
              recoverBy = player,
              skillName = chenglie.name,
            }
          end
        end
      end
    end
  end,
})

return chenglie
