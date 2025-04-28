local shanjia = fk.CreateSkill{
  name = "ol__shanjia",
}

Fk:loadTranslationTable{
  ["ol__shanjia"] = "缮甲",
  [":ol__shanjia"] = "游戏开始时，你获得3个“损”标记。当你失去装备牌后，你移去1个“损”。出牌阶段限一次，你可以摸三张牌，"..
  "并可以使用一张【杀】。然后你此阶段使用下X张手牌时，你弃置一张牌（X为“损”数）。若如此做，此阶段结束时，若你此阶段未因“缮甲”弃置过牌或"..
  "仅弃置过装备牌，你可以视为使用一张无距离限制的【杀】。",

  ["@ol__shanjia"] = "损",
  ["#ol__shanjia"] = "缮甲：你可以摸三张牌，使用一张【杀】",
  ["#ol__shanjia-use"] = "缮甲：你可以使用一张【杀】",
  ["#ol__shanjia-slash"] = "缮甲：你可以视为使用一张无距离限制的【杀】",

  ["$ol__shanjia1"] = "虎豹骁骑，甲兵自当冠宇天下。",
  ["$ol__shanjia2"] = "非虎贲难入我营，唯坚铠方配锐士。",
}

shanjia:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@ol__shanjia", 0)
end)

shanjia:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#ol__shanjia",
  card_num = 0,
  target_num = 0,
  can_use = function (self, player)
    return player:usedEffectTimes(shanjia.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function (self, room, effect)
    local player = effect.from
    player:drawCards(3, shanjia.name)
    if player.dead then return end
    local use = room:askToUseCard(player, {
      skill_name = shanjia.name,
      pattern = "slash",
      prompt = "#ol__shanjia-use",
      cancelable = true,
      extra_data = {
        bypass_times = true,
      },
    })
    if use then
      use.extraUse = true
      room:useCard(use)
    end
    if player.dead then return end
    if not player.dead and player:getMark("@ol__shanjia") > 0 then
      room:setPlayerMark(player, "ol__shanjia_using-phase", player:getMark("@ol__shanjia"))
    end
  end,
})
shanjia:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(shanjia.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@ol__shanjia", 3)
  end,
})
shanjia:addEffect(fk.AfterCardsMove, {
  mute = true,
  is_delay_effect = true,
  trigger_times = function(self, event, target, player, data)
    local i = 0
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            i = i + 1
          end
        end
      end
    end
    return i
  end,
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@ol__shanjia") > 0 then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@ol__shanjia", 1)
  end,
})
shanjia:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("ol__shanjia_using-phase") > 0 and
      data:IsUsingHandcard(player)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "ol__shanjia_using-phase", 1)
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = shanjia.name,
      cancelable = false,
    })
  end,
})
shanjia:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      player:usedEffectTimes(shanjia.name, Player.HistoryPhase) > 0 and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.skillName == shanjia.name and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              return Fk:getCardById(info.cardId).type ~= Card.TypeEquip
            end
          end
        end
      end, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = shanjia.name,
      prompt = "#ol__shanjia-slash",
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

return shanjia
