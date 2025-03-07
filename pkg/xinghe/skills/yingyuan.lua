local yingyuan = fk.CreateSkill{
  name = "ol__yingyuan",
}

Fk:loadTranslationTable{
  ["ol__yingyuan"] = "应援",
  [":ol__yingyuan"] = "当你于回合内使用牌后，你可以令一名其他角色获得牌堆中一张类别相同的牌。每回合每种类别限一次。",

  ["#ol__yingyuan-choose"] = "应援：你可以令一名角色从牌堆获得一张%arg",

  ["$ol__yingyuan1"] = "我为后援，卿大可放心！",
  ["$ol__yingyuan2"] = "运筹帷幄，粮草调度，一应俱全。",
}

yingyuan:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingyuan.name) and
      player.room.current == player and #player.room:getOtherPlayers(player, false) > 0 and
      not table.contains(player:getTableMark("ol__yingyuan-turn"), data.card.type)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = yingyuan.name,
      prompt = "#ol__yingyuan-choose:::"..data.card:getTypeString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "ol__yingyuan-turn", data.card.type)
    local to = event:getCostData(self).tos[1]
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|"..data.card:getTypeString(), 1, "drawPile")
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonJustMove, yingyuan.name, nil, false, to)
    end
  end,
})

return yingyuan
