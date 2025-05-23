local zelie = fk.CreateSkill {
  name = "zelie",
  tags = { Skill.Family },
}

Fk:loadTranslationTable{
  ["zelie"] = "泽烈",
  [":zelie"] = "宗族技，当一名同族角色失去其场上的最后一张牌后，你可以令一名角色本回合下一次摸牌/弃牌后，其再摸一张牌/弃一张牌。",

  ["#zelie-choose"] = "泽烈：你可以令一名角色本回合下次摸牌再摸一张牌/弃牌后再弃一张牌",
  ["@zelie_draw-turn"] = "泽烈 摸牌",
  ["@zelie_discard-turn"] = "泽烈 弃牌",
}

local U = require "packages/utility/utility"

zelie:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  trigger_times = function(self, event, target, player, data)
    local tos = {}
    if player:hasSkill(zelie.name) then
      for _, move in ipairs(data) do
        if move.from and U.FamilyMember(player, move.from) and #move.from:getCardIds("ej") == 0 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerJudge then
              table.insertIfNeed(tos, move.from)
            end
          end
        end
      end
    end
    return #tos
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zelie.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "zelie_active",
      prompt = "#zelie-choose",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    room:addPlayerMark(to, "@"..choice.."-turn", 1)
  end,
})

zelie:addEffect(fk.AfterCardsMove, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if player:getMark("@zelie_draw-turn") > 0 then
      for _, move in ipairs(data) do
        if move.to == player and move.moveReason == fk.ReasonDraw then
          return true
        end
      end
    end
    if player:getMark("@zelie_discard-turn") > 0 then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    for _, move in ipairs(data) do
      if move.to == player and move.moveReason == fk.ReasonDraw then
        table.insertIfNeed(choices, "draw")
      end
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(choices, "discard")
          end
        end
      end
    end
    if player:getMark("@zelie_draw-turn") > 0 and table.contains(choices, "draw") then
      local n = player:getMark("@zelie_draw-turn")
      room:setPlayerMark(player, "@zelie_draw-turn", 0)
      player:drawCards(n, zelie.name)
      if player.dead then return end
    end
    if player:getMark("@zelie_discard-turn") > 0 and table.contains(choices, "discard") then
      local n = player:getMark("@zelie_discard-turn")
      room:setPlayerMark(player, "@zelie_discard-turn", 0)
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = zelie.name,
        cancelable = false,
      })
    end
  end,
})

return zelie
