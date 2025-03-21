local qingyi = fk.CreateSkill{
  name = "qingyix",
}

Fk:loadTranslationTable{
  ["qingyix"] = "清议",
  [":qingyix"] = "出牌阶段限一次，你可以与至多两名有牌的其他角色同时弃置一张牌，若类型相同，你可以重复此流程。若以此法弃置了两种颜色的牌，"..
  "结束阶段，你可以获得其中颜色不同的牌各一张。",

  ["#qingyix"] = "清议：与至多两名角色同时弃置一张牌，若类型相同可以重复此流程",
  ["#qingyi-invoke"] = "清议：是否继续发动“清议”？",
  ["#qingyix-prey"] = "清议：获得其中颜色不同的牌各一张",

  ["$qingyix1"] = "布政得失，愿与诸君共议。",
  ["$qingyix2"] = "领军伐谋，还请诸位献策。",
}

qingyi:addEffect("active", {
  anim_type = "control",
  prompt = "#qingyix",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  can_use = function(self, player)
    return not player:isNude() and player:usedEffectTimes(qingyi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < 2 and to_select ~= player and not to_select:isNude()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local mark = player:getTableMark("qingyi-turn")
    local targets = table.simpleClone(effect.tos)
    table.insert(targets, player)
    while not player.dead do
      local result = room:askToJointCards(player, {
        players = targets,
        min_num = 1,
        max_num = 1,
        includeEquip = true,
        cancelable = false,
        pattern = ".|.|.|hand,equip",
        skill_name = qingyi.name,
        prompt = "#AskForDiscard:::1:1",
        will_throw = true,
      })
      local moves = {}
      local chosen = {}
      for _, p in ipairs(targets) do
        local throw = result[p][1]
        if throw then
          table.insert(chosen, throw)
          table.insertIfNeed(mark, throw)
          table.insert(moves, {
            ids = {throw},
            from = p,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonDiscard,
            proposer = p,
            skillName = qingyi.name,
          })
        end
      end
      if #moves == 0 then break end
      room:moveCards(table.unpack(moves))
      if table.find(targets, function(p)
        return #(result[p] or {}) == 0
      end) or
      table.find(targets, function(p)
        return p:isNude()
      end) or
      table.find(chosen, function(id)
        return Fk:getCardById(id).type ~= Fk:getCardById(chosen[1]).type
      end) or
      not room:askToSkillInvoke(player, {
        skill_name = qingyi.name,
        prompt = "#qingyi-invoke",
      }) then
        break
      end
    end
    if not player.dead then
      room:setPlayerMark(player, "qingyi-turn", mark)
    end
  end,
})
qingyi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(qingyi.name) and player.phase == Player.Finish then
      local cards = table.filter(player:getTableMark("qingyi-turn"), function(id)
        return table.contains(player.room.discard_pile, id)
      end)
      if #table.filter(cards, function (id)
        return Fk:getCardById(id).color == Card.Red
      end) > 0 and
      #table.filter(cards, function (id)
        return Fk:getCardById(id).color == Card.Black
      end) > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = room:askToPoxi(player, {
      poxi_type = qingyi.name,
      data = {
        { qingyi.name, event:getCostData(self).cards },
      },
      cancelable = true,
    })
    if #result == 2 then
      room:moveCardTo(result, Card.PlayerHand, player, fk.ReasonJustMove, qingyi.name, nil, true, player)
    end
  end,
})

Fk:addPoxiMethod{
  name = "qingyix",
  prompt = "#qingyix-prey",
  card_filter = function(to_select, selected, data)
    if #selected < 2 then
      if #selected == 0 then
        return true
      else
        return Fk:getCardById(to_select).color ~= Fk:getCardById(selected[1]).color
      end
    end
  end,
  feasible = function(selected)
    return #selected == 2
  end,
}

return qingyi
