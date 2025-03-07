local yuhua = fk.CreateSkill{
  name = "ol__yuhua",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__yuhua"] = "羽化",
  [":ol__yuhua"] = "锁定技，你的非基本牌不计入手牌上限；准备阶段或结束阶段，你观看牌堆顶的一张牌，以任意顺序置于牌堆顶或牌堆底。",

  ["$ol__yuhua1"] = "虹衣羽裳，出尘入仙。",
  ["$ol__yuhua2"] = "羽化成蝶，翩仙舞愿。",
}

yuhua:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuhua.name) and
      (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local extra = 0
    if player:getMark("ol__yuhua_extra") ~= 0 then
      local turn_id = -1
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event then
        turn_id = turn_event.id
      end
      extra = #table.filter(player:getTableMark("ol__yuhua_extra"), function (id)
        return id ~= turn_id
      end)
    end
    room:askToGuanxing(player, {
      cards = room:getNCards(math.min(5, 1 + extra)),
    })
  end,
})
yuhua:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(yuhua.name) and card.type ~= Card.TypeBasic
  end,
})

return yuhua
