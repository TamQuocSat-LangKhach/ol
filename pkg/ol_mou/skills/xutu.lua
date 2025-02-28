local xutu = fk.CreateSkill{
  name = "xutu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xutu"] = "徐图",
  [":xutu"] = "锁定技，游戏开始时，你将牌堆顶三张牌置于你的武将牌上，称为“资”。每个结束阶段，你将本回合弃牌堆的一张牌与一张“资”交换，然后"..
  "令一名角色获得三张花色或点数相同的“资”，若如此做，你将“资”补至三张。",

  ["xutu_supplies"] = "资",
  ["#xutu"] = "徐图：将本回合弃牌堆的一张牌与一张“资”交换",
  ["#xutu-give"] = "徐图：令一名角色获得“资”",
}

Fk:addPoxiMethod{
  name = "xutu",
  prompt = function (data, extra_data)
    return "#xutu"
  end,
  card_filter = function (to_select, selected, data, extra_data)
    if data and #selected < 2 then
      for _, id in ipairs(selected) do
        for _, v in ipairs(data) do
          if table.contains(v[2], id) and table.contains(v[2], to_select) then
            return false
          end
        end
      end
      return true
    end
  end,
  feasible = function(selected, data)
    return data and #selected == 2
  end,
  default_choice = function(data)
    if not data then return {} end
    local cids = table.map(data, function(v) return v[2][1] end)
    return cids
  end,
}

xutu:addEffect(fk.GameStart, {
  derived_piles = "xutu_supplies",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xutu.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:addToPile("xutu_supplies", room:getNCards(3), true, xutu.name, player)
  end,
})
xutu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xutu.name) and target.phase == Player.Finish and #player:getPile("xutu_supplies") > 0 then
      local cards = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end, Player.HistoryTurn)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card_data = {
      {"xutu_supplies", player:getPile("xutu_supplies")},
      {"pile_discard", event:getCostData(self).cards},
    }
    local cards = room:askToPoxi(player, {
      poxi_type = xutu.name,
      data = card_data,
      cancelable = false,
    })
    local cards1, cards2 = {cards[1]}, {cards[2]}
    if table.contains(player:getPile("xutu_supplies"), cards[2]) then
      cards1, cards2 = {cards[2]}, {cards[1]}
    end
    room:moveCards({
      ids = cards1,
      from = player,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonExchange,
      skillName = xutu.name,
      proposer = player,
      moveVisible = true,
    },
    {
      ids = cards2,
      to = player,
      toArea = Card.PlayerSpecial,
      specialName = "xutu_supplies",
      moveReason = fk.ReasonExchange,
      skillName = xutu.name,
      proposer = player,
      moveVisible = true,
    })
    if player.dead then return end
    local pile = player:getPile("xutu_supplies")
    if #pile == 3 and
      (table.every(pile, function (id)
        return Fk:getCardById(id).number == Fk:getCardById(pile[1]).number
      end) or
      table.every(pile, function (id)
        return Fk:getCardById(id):compareSuitWith(Fk:getCardById(pile[1]))
      end)) then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = room.alive_players,
          skill_name = xutu.name,
          prompt = "#xutu-give",
          cancelable = false,
        })[1]
      room:moveCardTo(player:getPile("xutu_supplies"), Card.PlayerHand, to, fk.ReasonJustMove, xutu.name, nil, true, to)
      if player:hasSkill(xutu.name) and #player:getPile("xutu_supplies") < 3 then
        player:addToPile("xutu_supplies", room:getNCards(3 - #player:getPile("xutu_supplies")), true, xutu.name, player)
      end
    end
  end,
})

return xutu
