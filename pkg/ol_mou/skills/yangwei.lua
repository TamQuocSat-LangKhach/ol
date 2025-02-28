local yangwei = fk.CreateSkill{
  name = "yangwei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yangwei"] = "扬威",
  [":yangwei"] = "锁定技，当你一回合于摸牌阶段外摸至少两张牌后，你下一次造成伤害+1；当你一回合于弃牌阶段外弃置至少两张牌后，你下一次受到伤害+1。",

  ["@yangwei1"] = "伤害+",
  ["@yangwei2"] = "受伤+",

  ["$yangwei1"] = "本将军刀下，不分强弱，只问生死。",
  ["$yangwei2"] = "敌将何在？速来受死！",
}

yangwei:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yangwei.name) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      for _, move in ipairs(data) do
        if move.to == player and move.moveReason == fk.ReasonDraw and player.phase ~= Player.Draw and
          player:getMark("yangwei1_count-turn") > 1 and player:getMark("yangwei1-turn") == 0 then
          return true
        end
        if move.from == player and move.moveReason == fk.ReasonDiscard and player.phase ~= Player.Discard and
          player:getMark("yangwei2_count-turn") > 1 and player:getMark("yangwei2-turn") == 0 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to == player and move.moveReason == fk.ReasonDraw and player.phase ~= Player.Draw and
        player:getMark("yangwei1_count-turn") > 1 and player:getMark("yangwei1-turn") == 0 then
        room:setPlayerMark(player, "yangwei1-turn", 1)
        room:addPlayerMark(player, "@yangwei1", 1)
      end
      if move.from == player and move.moveReason == fk.ReasonDiscard and player.phase ~= Player.Discard and
        player:getMark("yangwei2_count-turn") > 1 and player:getMark("yangwei2-turn") == 0 then
        room:setPlayerMark(player, "yangwei2-turn", 1)
        room:addPlayerMark(player, "@yangwei2", 1)
      end
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(yangwei.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn_event == nil then return end
    for _, move in ipairs(data) do
      if move.to == player and move.moveReason == fk.ReasonDraw and player.phase ~= Player.Draw then
        room:addPlayerMark(player, "yangwei1_count-turn", #move.moveInfo)
      end
      if move.from == player and move.moveReason == fk.ReasonDiscard and player.phase ~= Player.Discard then
        room:addPlayerMark(player, "yangwei2_count-turn", #move.moveInfo)
      end
    end
  end,
})
yangwei:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@yangwei1") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(player:getMark("@yangwei1"))
    player.room:setPlayerMark(player, "@yangwei1", 0)
  end,
})
yangwei:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@yangwei2") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(player:getMark("@yangwei2"))
    player.room:setPlayerMark(player, "@yangwei2", 0)
  end,
})

return yangwei
