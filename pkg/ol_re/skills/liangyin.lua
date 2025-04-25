local liangyin = fk.CreateSkill{
  name = "ol__liangyin",
}

Fk:loadTranslationTable{
  ["ol__liangyin"] = "良姻",
  [":ol__liangyin"] = "当每回合首次有牌被置于武将牌上/从武将牌上移入游戏后，你可以与一名其他角色各摸/弃置一张牌，然后你可以令其中一名手牌数"..
  "为X的角色回复1点体力（X为“箜”数）。",

  ["#ol__liangyin-drawcard"] = "良姻：你可以与一名角色各摸一张牌",
  ["#ol__liangyin-discard"] = "良姻：你可以与一名角色各弃置一张牌",
  ["#ol__liangyin-recover"] = "良姻：你可以令一名角色回复1点体力",

  ["$ol__liangyin1"] = "碧水云月间，良缘情长在。",
  ["$ol__liangyin2"] = "皓月皎，花景明，两心同。",
}

liangyin:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(liangyin.name) and #player.room:getOtherPlayers(player, false) > 0 then
      local x, y = player:getMark("ol__liangyin1_record-turn"), player:getMark("ol__liangyin2_record-turn")
      local room = player.room
      local move__event = room.logic:getCurrentEvent()
      local turn_event = move__event:findParent(GameEvent.Turn)
      if turn_event == nil then return false end
      if not move__event or (x > 0 and x ~= move__event.id and y > 0 and y ~= move__event.id) then return false end
      local liangyin1_search, liangyin2_search = false, false
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerSpecial then
          if x == 0 then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea ~= Card.PlayerSpecial then
                liangyin1_search = true
              end
            end
          end
        elseif y == 0 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerSpecial then
              liangyin2_search = true
            end
          end
        end
      end
      if liangyin1_search or liangyin2_search then
        room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          local moves = e.data
          for _, move in ipairs(moves) do
            if move.toArea == Card.PlayerSpecial then
              if liangyin1_search then
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea ~= Card.PlayerSpecial then
                    x = e.id
                    room:setPlayerMark(player, "ol__liangyin1_record-turn", x)
                    liangyin1_search = false
                  end
                end
              end
            elseif liangyin2_search then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerSpecial then
                  y = e.id
                  room:setPlayerMark(player, "ol__liangyin2_record-turn", y)
                  liangyin2_search = false
                end
              end
            end
            if not (liangyin1_search or liangyin2_search) then return true end
          end
          return false
        end, Player.HistoryTurn)
      end
      return x == move__event.id or y == move__event.id
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local x, y = player:getMark("ol__liangyin1_record-turn"), player:getMark("ol__liangyin2_record-turn")
    local move__event = room.logic:getCurrentEvent()
    if x == move__event.id then
      event:setCostData(self, {choice = "drawcard"})
      self:doCost(event, target, player, data)
    end
    if y == move__event.id and player:hasSkill(liangyin.name) and not player:isNude() then
      event:setCostData(self, {choice = "discard"})
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local targets = table.filter(room.alive_players, function (p)
      return p ~= player and (choice == "drawcard" or not p:isNude())
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = liangyin.name,
      prompt = "#ol__liangyin-"..choice,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if choice == "drawcard" then
      room:notifySkillInvoked(player, liangyin.name, "support")
      player:broadcastSkillInvoke(liangyin.name)
      player:drawCards(1, liangyin.name)
      if not to.dead then
        to:drawCards(1, liangyin.name)
      end
    elseif choice == "discard" then
      room:notifySkillInvoked(player, liangyin.name, "control")
      player:broadcastSkillInvoke(liangyin.name)
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = liangyin.name,
        cancelable = false,
      })
      if not to.dead then
        room:askToDiscard(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = liangyin.name,
          cancelable = false,
        })
      end
    end
    if player.dead then return false end
    local targets = table.filter({player, to}, function (p)
      return p:getHandcardNum() == #player:getPile("ol__kongsheng_harp") and p:isWounded()
    end)
    if #targets == 0 then return end
    to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = liangyin.name,
      prompt = "#ol__liangyin-recover",
      cancelable = true,
    })
    if #to > 0 then
      room:recover{
        who = to[1],
        num = 1,
        recoverBy = player,
        skillName = liangyin.name,
      }
    end
  end,
})

return liangyin
