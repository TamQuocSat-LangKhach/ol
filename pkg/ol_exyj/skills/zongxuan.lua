
local zongxuan = fk.CreateSkill{
  name = "ol_ex__zongxuan",
}

Fk:loadTranslationTable{
  ["ol_ex__zongxuan"] = "纵玄",
  [":ol_ex__zongxuan"] = "当你的牌因弃置而置入弃牌堆后，或你上家的牌于当前回合内第一次因弃置而置入弃牌堆后，"..
  "你可以将其中任意张牌置于牌堆顶。",

  ["#ol_ex__zongxuan-invoke"] = "纵玄：将任意数量的弃牌置于牌堆顶",
  ["#PutKnownCardtoDrawPile"] = "%from 将 %card 置于牌堆顶",

  ["$ol_ex__zongxuan1"] = "易字从日下月，此乃自然之理。",
  ["$ol_ex__zongxuan2"] = "笔著太玄十四卷，继往圣之学。",
}

zongxuan:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zongxuan.name) then
      local cards1, cards2 = {}, {}
      local room = player.room
      local last_player_id = 0
      local last_player
      local mark = 0
      local move_event = room.logic:getCurrentEvent():findParent(GameEvent.MoveCards, true)
      if not player:isRemoved() then
        last_player = player:getLastAlive(false)
        if last_player ~= player and move_event ~= nil then
          mark = last_player:getMark("ol_ex__zongxuan_record-turn")
          if mark == 0 or mark == move_event.id then
            last_player_id = last_player.id
          end
        end
      end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insertIfNeed(cards1, info.cardId)
              end
            end
          elseif move.from == last_player_id then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insertIfNeed(cards2, info.cardId)
              end
            end
          end
        end
      end
      cards1 = room.logic:moveCardsHoldingAreaCheck(cards1)
      if #cards2 > 0 then
        if mark == 0 then
          room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
            for _, move in ipairs(e.data) do
              if move.from.id == last_player_id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard and
              table.find(move.moveInfo, function (info)
                return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
              end) then
                mark = e.id
                room:setPlayerMark(last_player, "ol_ex__zongxuan_record-turn", mark)
                return true
              end
            end
            return false
          end, Player.HistoryTurn)
          if mark ~= move_event.id then
            cards2 = {}
          end
        end
      end
      if #cards2 > 0 then
        table.insertTable(cards1, room.logic:moveCardsHoldingAreaCheck(cards2))
      end
      if #cards1 > 0 then
        event:setCostData(self, {cards = cards1})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local top = room:askToArrangeCards(player, {
      skill_name = zongxuan.name,
      card_map = {event:getCostData(self).cards, "pile_discard","Top"},
      prompt = "#ol_ex__zongxuan-invoke",
      free_arrange = true,
      box_size = 7,
      max_limit = {0, 1},
    })[2]
    room:sendLog{
      type = "#PutKnownCardtoDrawPile",
      from = player.id,
      card = top
    }
    top = table.reverse(top)
    room:moveCards({
      ids = top,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = zongxuan.name,
      proposer = player,
      moveVisible = true,
    })
  end,
})

return zongxuan