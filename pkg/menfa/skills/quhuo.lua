local quhuo = fk.CreateSkill{
  name = "quhuo",
  tags = { Skill.Family },
}

Fk:loadTranslationTable{
  ["quhuo"] = "去惑",
  [":quhuo"] = "宗族技，当你不因使用、打出或弃置失去手牌后，若其中每回合首次有【酒】或装备牌，你可以令一名同族角色回复1点体力。",

  ["#quhuo-choose"] = "去惑：你可以令一名同族角色回复1点体力",
}

local U = require "packages/utility/utility"

quhuo:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(quhuo.name) and player:getMark("quhuo-turn") == 0 then
      local yes = false
      for _, move in ipairs(data) do
        if move.from == player and
          not table.contains({fk.ReasonUse, fk.ReasonResponse, fk.ReasonDiscard}, move.moveReason) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and
              (Fk:getCardById(info.cardId).name == "analeptic" or Fk:getCardById(info.cardId).type == Card.TypeEquip) then
              yes = true
              break
            end
          end
        end
      end
      if yes then
        local move_events = player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          for _, move in ipairs(e.data) do
            if move.from == player and
              not table.contains({fk.ReasonUse, fk.ReasonResponse, fk.ReasonDiscard}, move.moveReason) then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand and
                  (Fk:getCardById(info.cardId).name == "analeptic" or Fk:getCardById(info.cardId).type == Card.TypeEquip) then
                  return true
                end
              end
            end
          end
        end, Player.HistoryTurn)
        if #move_events == 1 then
          player.room:setPlayerMark(player, "quhuo-turn", 1)
          return move_events[1].data == data and
            table.find(player.room.alive_players, function (p)
              return U.FamilyMember(player, p) and p:isWounded()
            end)
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return U.FamilyMember(player, p) and p:isWounded()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = quhuo.name,
      prompt = "#quhuo-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:recover{
      who = to,
      num = 1,
      recoverBy = player,
      skillName = quhuo.name,
    }
  end,
})

return quhuo
