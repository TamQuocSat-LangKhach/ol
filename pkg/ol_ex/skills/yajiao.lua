local yajiao = fk.CreateSkill {
  name = "ol_ex__yajiao",
}

Fk:loadTranslationTable {
  ["ol_ex__yajiao"] = "涯角",
  [":ol_ex__yajiao"] = "当你于回合外使用或打出手牌时，你可以亮出牌堆顶的一张牌，然后若这两张牌类别相同，"..
  "则你将之交给一名角色或放回牌堆顶，否则你可以弃置一名攻击范围内包含你的其他角色区域里的一张牌并将亮出的牌放回牌堆顶。",

  ["#ol_ex__yajiao-give"] = "涯角：将%arg交给1名角色，点取消则放回牌堆顶",
  ["#ol_ex__yajiao-throw"] = "涯角：可以弃置1名攻击范围内包含你的其他角色区域里的1张牌",

  ["$ol_ex__yajiao1"] = "以死博生，无敌不克！",
  ["$ol_ex__yajiao2"] = "一枪在手，贼军何足道哉！",
}

yajiao:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yajiao.name) and player.room:getCurrent() ~= player then
      for _, move in ipairs(data) do
        if move.from == player and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResponse) and
        table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand
        end) then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(1)
    room:turnOverCardsFromDrawPile(player, cards, yajiao.name)
    if player.dead then
      room:returnCardsToDrawPile(player, cards, yajiao.name)
      return false
    end
    local card_type = nil
    local move_event = room.logic:getCurrentEvent():findParent(GameEvent.MoveCards, true)
    if move_event then
      local parent_event = move_event.parent
      if parent_event == GameEvent.UseCard or parent_event == GameEvent.RespondCard then
        card_type = parent_event.data.card.type
      else
        --改判的情况为将一张牌以打出的方式置入处理区，无上级打出事件，因此特殊处理
        for _, move in ipairs(data) do
          if move.from == player and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResponse) and
          #move.moveInfo == 1 then
            card_type = Fk:getCardById(move.moveInfo[1].cardId, true).type
            break
          end
        end
      end
    end
    local card = Fk:getCardById(cards[1])

    if card_type and card_type == card.type then
      local tos = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#ol_ex__yajiao-give:::" .. card:toLogString(),
        skill_name = yajiao.name,
        cancelable = true,
      })
      if #tos > 0 then
        room:obtainCard(tos[1], cards, true, fk.ReasonGive, player, yajiao.name)
      else
        room:returnCardsToDrawPile(player, cards, yajiao.name)
      end
    else
      local tos = room:askToChoosePlayers(player, {
        targets = table.filter(room.alive_players, function (p)
          return not p:isAllNude() and p:inMyAttackRange(player)
        end),
        min_num = 1,
        max_num = 1,
        prompt = "#ol_ex__yajiao-throw",
        skill_name = yajiao.name,
        cancelable = true,
      })
      if #tos > 0 then
        local cid = room:askToChooseCard(player, {
          target = tos[1],
          flag = "hej",
          skill_name = yajiao.name,
        })
        room:throwCard(cid, yajiao.name, tos[1], player)
      end
      room:returnCardsToDrawPile(player, cards, yajiao.name)
    end
  end,
})

return yajiao
