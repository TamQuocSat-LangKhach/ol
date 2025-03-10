local qirang = fk.CreateSkill{
  name = "ol__qirang",
}

Fk:loadTranslationTable{
  ["ol__qirang"] = "祈禳",
  [":ol__qirang"] = "当你使用装备牌结算后，你可以获得牌堆中的一张锦囊牌，若此牌：为普通锦囊牌，你使用此牌仅指定一个目标时，"..
  "可以额外指定一个目标；不为普通锦囊牌，你下个回合发动〖羽化〗时观看的牌数+1（至多加至5）。",

  ["@@ol__qirang-inhand"] = "祈禳",
  ["#ol__qirang-choose"] = "祈禳：你可以为%arg额外指定一个目标",

  ["$ol__qirang1"] = "求福禳灾，家和万兴。",
  ["$ol__qirang2"] = "禳解百祸，祈运千秋。",
}

qirang:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qirang.name) and data.card.type == Card.TypeEquip
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick")
    if #cards > 0 then
      local card = Fk:getCardById(cards[1])
      if card.sub_type == Card.SubtypeDelayedTrick then
        local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
        if turn_event then
          room:addTableMark(player, "ol__yuhua_extra", turn_event.id)
        else
          room:addTableMark(player, "ol__yuhua_extra", 0)
        end
      end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, qirang.name, nil, false, player,
        card:isCommonTrick() and "@@ol__qirang-inhand" or "")
    end
  end,
})
qirang:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@@ol__qirang-inhand") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.ol__qirang = player
  end,
})
qirang:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.ol__qirang == player and
      #data.tos == 1 and #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = data:getExtraTargets(),
      skill_name = qirang.name,
      prompt = "#ol__qirang-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})
qirang:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("ol__yuhua_extra") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local record = player:getTableMark("ol__yuhua_extra")
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then return end
    for i = #record, 1, -1 do
      if record[i] ~= turn_event.id then
        table.remove(record, i)
      end
    end
    if #record == 0 then
      room:setPlayerMark(player, "ol__yuhua_extra", 0)
    else
      room:setPlayerMark(player, "ol__yuhua_extra", record)
    end
  end,
})

return qirang
