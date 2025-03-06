local zhaohuo = fk.CreateSkill{
  name = "ol__zhaohuo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__zhaohuo"] = "招祸",
  [":ol__zhaohuo"] = "锁定技，一名角色于你的回合内首次受到伤害后，其须交给你一张手牌。你不能使用或打出这些牌，且不计入手牌上限，直到回合结束。",

  ["#ol__zhaohuo-give"] = "招祸：请交给 %src 一张手牌",
  ["@@ol__zhaohuo-inhand-turn"] = "招祸",

  ["$ol__zhaohuo1"] = "曹军如狼似虎，我徐州百姓何辜？",
  ["$ol__zhaohuo2"] = "这是那张闿所为，与我陶谦有何干系？",
}

zhaohuo:addEffect(fk.Damaged, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if target ~= player and player:hasSkill(zhaohuo.name) and not target:isKongcheng() and not target.dead then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil or turn_event.data.who ~= player then return end
      local events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == target
      end, Player.HistoryTurn)
      if #events == 1 and events[1] == player.room.logic:getCurrentEvent() then
        event:setCostData(self, {tos = {target}})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = zhaohuo.name,
      prompt = "#ol__zhaohuo-give:"..player.id,
      cancelable = false,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, zhaohuo.name, nil, false, target, "@@ol__zhaohuo-inhand-turn")
  end,
})
zhaohuo:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local subcards = card:isVirtual() and card.subcards or {card.id}
    return #subcards > 0 and table.find(subcards, function(id)
      return Fk:getCardById(id):getMark("@@ol__zhaohuo-inhand-turn") > 0
    end)
  end,
  prohibit_response = function(self, player, card)
    local subcards = card:isVirtual() and card.subcards or {card.id}
    return #subcards > 0 and table.find(subcards, function(id)
      return Fk:getCardById(id):getMark("@@ol__zhaohuo-inhand-turn") > 0
    end)
  end,
})
zhaohuo:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@ol__zhaohuo-inhand-turn") > 0
  end,
})

return zhaohuo
