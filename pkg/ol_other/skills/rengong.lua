local rengong = fk.CreateSkill {
  name = "rengong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["rengong"] = "人公",
  [":rengong"] = "锁定技，当你连续使用两张类别不同的牌后，你弃置一张牌，然后从牌堆获得一张另一类别的牌。",

  ["$rengong1"] = "天父地母，人生象天属天，人卒象地属地。",
  ["$rengong2"] = "三弟谨记，天封人以道，地封人以养德。",
}

rengong:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(rengong.name) and not player:isNude() then
      local types = {"basic", "trick", "equip"}
      table.removeOne(types, data.card:getTypeString())
      player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function(e)
        if e.id < player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true).id then
          local use = e.data
          if use.from == player then
            table.removeOne(types, use.card:getTypeString())
            return true
          end
        end
      end, 0)
      if #types == 1 then
        event:setCostData(self, {choice = types[1]})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = rengong.name,
      cancelable = false,
    }) > 0 and
      not player.dead then
      local type = event:getCostData(self).choice
      local card = room:getCardsFromPileByRule(".|.|.|.|.|"..type)
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, rengong.name, nil, false, player)
      end
    end
  end,
})

return rengong
