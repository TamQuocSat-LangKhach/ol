local huishi = fk.CreateSkill{
  name = "ol__huishi",
}

Fk:loadTranslationTable{
  ["ol__huishi"] = "慧识",
  [":ol__huishi"] = "摸牌阶段，你可以放弃摸牌，改为观看牌堆顶的X张牌，获得其中的一半（向下取整），然后将其余牌置于牌堆底。（X为牌堆牌数的个位数）",

  ["#ol__huishi-invoke"] = "慧识：你可以放弃摸牌，改为观看牌堆顶%arg张牌并获得其中的一半，其余置于牌堆底",

  ["$ol__huishi1"] = "你的想法，我已知晓。",
  ["$ol__huishi2"] = "妾身慧眼，已看透太多。",
}

huishi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huishi.name) and player.phase == Player.Draw and
      #player.room.draw_pile % 10 > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:askToSkillInvoke(player, {
      skill_name = huishi.name,
      prompt = "#ol__huishi-invoke:::"..#room.draw_pile % 10
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    local x = #room.draw_pile % 10
    if x == 0 then return end
    local cards = room:turnOverCardsFromDrawPile(player, room:getNCards(x), huishi.name)
    local y = x // 2
    local rusult = room:askToGuanxing(player, {
      cards = cards,
      top_limit = {x - y, x},
      bottom_limit = {y, y},
      skill_name = huishi.name,
      skip = true,
      area_names = {"Bottom", "toObtain"},
    })
    room:moveCardTo(rusult.bottom, Player.Hand, player, fk.ReasonPrey, huishi.name, nil, false, player)
    room:moveCards {
      ids = rusult.top,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = huishi.name,
      proposer = player,
      moveVisible = false,
      visiblePlayers = player,
      drawPilePosition = -1,
    }
  end,
})

return huishi
