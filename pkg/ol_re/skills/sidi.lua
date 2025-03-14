local sidi = fk.CreateSkill{
  name = "ol__sidi",
}

Fk:loadTranslationTable{
  ["ol__sidi"] = "司敌",
  [":ol__sidi"] = "其他角色出牌阶段开始时，你可以弃置一张与你装备区里任意牌颜色相同的非基本牌，令其本阶段不能使用和打出与此牌颜色相同的牌，"..
  "然后此阶段结束时，若其本阶段未使用过【杀】，你视为对其使用一张【杀】。",

  ["#ol__sidi-invoke"] = "司敌：弃置与装备区内牌颜色相同的非基本牌，令 %dest 本阶段不能使用打出此颜色牌",
  ["@ol__sidi-turn"] = "司敌",

  ["$ol__sidi1"] = "扼守关中，以静制动。",
  ["$ol__sidi2"] = "料敌为先，破敌为备。",
}

sidi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(sidi.name) and target.phase == Player.Play and not target.dead and
      #player:getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("he"), function (id)
      return Fk:getCardById(id).type ~= Card.TypeBasic and not player:prohibitDiscard(id) and
        table.find(player:getCardIds("e"), function (id2)
          return Fk:getCardById(id):compareColorWith(Fk:getCardById(id2))
        end) ~= nil
    end)
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = sidi.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#ol__sidi-invoke::"..target.id,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local color = Fk:getCardById(event:getCostData(self).cards[1]):getColorString()
    room:throwCard(event:getCostData(self).cards, sidi.name, player, player)
    if not target.dead then
      room:addTableMarkIfNeed(target, "@ol__sidi-turn", color)
    end
  end,
})
sidi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if table.contains(player:getTableMark("@ol__sidi-turn"), card:getColorString()) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0
    end
  end,
  prohibit_response = function(self, player, card)
    if table.contains(player:getTableMark("@ol__sidi-turn"), card:getColorString()) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0
    end
  end,
})
sidi:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes(sidi.name, Player.HistoryPhase) > 0 and not player.dead and not target.dead and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == target and use.card.trueName == "slash"
      end, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("slash", nil, player, target, sidi.name, true)
  end,
})

return sidi
