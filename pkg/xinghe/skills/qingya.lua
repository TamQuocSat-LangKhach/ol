local qingya = fk.CreateSkill{
  name = "qingya",
}

Fk:loadTranslationTable{
  ["qingya"] = "倾轧",
  [":qingya"] = "当你使用【杀】指定唯一目标后，你可以弃置你与其之间的角色各一张手牌，本回合下个阶段结束时，你可以使用其中一张牌。",

  ["#qingya-invoke"] = "倾轧：你可以弃置你与 %dest 之间一个方向上所有角色的各一张牌",
  ["#qingya-use"] = "倾轧：你可以使用其中一张牌",

  ["$qingya1"] = "罡风从虎，威震四方。",
  ["$qingya2"] = "铁车过处，寸草不生。",
}

qingya:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(qingya.name) and data.card.trueName == "slash" and
      #data.use.tos == 1 and not data.to.dead and
      #player.room.alive_players > 3 then
      local left, right = 0, 0
      local temp = player
      while temp ~= data.to do
        if not temp.dead then
          right = right + 1
        end
        temp = temp.next
      end
      left = #player.room.alive_players - right
      if math.min(left, right) > 1 then
        local choice = "both"
        if left > right then
          choice = "right"
        elseif left < right then
          choice = "left"
        end
        event:setCostData(self, {choice = choice})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"left", "right", "Cancel"}
    local choice = event:getCostData(self).choice
    if choice == "left" then
      table.removeOne(choices, "right")
    elseif choice == "right" then
      table.removeOne(choices, "left")
    end
    choice = room:askToChoice(player, {
      choices = choices,
      skill_name = qingya.name,
      prompt = "#qingya-invoke::"..data.to.id,
      all_choices = {"left", "right", "Cancel"},
    })
    if choice ~= "Cancel" then
      local tos = {}
      if choice == "left" then
        local temp = data.to.next
        while temp ~= player do
          if not temp.dead then
            table.insert(tos, temp)
          end
          temp = temp.next
        end
      else
        local temp = player.next
        while temp ~= data.to do
          if not temp.dead then
            table.insert(tos, temp)
          end
          temp = temp.next
        end
      end
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    local info = {0, {}}
    local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
    if phase_event then
      info[1] = phase_event.id
    end
    for _, p in ipairs(tos) do
      if not (p.dead or p:isKongcheng()) then
        local card = room:askToChooseCard(player, {
          target = p,
          flag = "h",
          skill_name = qingya.name,
        })
        table.insertIfNeed(info[2], card)
        room:throwCard(card, qingya.name, p, player)
        if player.dead then return end
      end
    end
    room:addTableMark(player, "qingya-turn", info)
  end,
})
qingya:addEffect(fk.EventPhaseEnd, {
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if player:getMark("qingya-turn") ~= 0 and not player.dead then
      local room = player.room
      local cards, current_id, new_info = {}, -1, {}
      local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
      if phase_event then
        current_id = phase_event.id
      end
      for _, info in ipairs(player:getMark("qingya-turn")) do
        if info[1] ~= current_id then
          table.insertTableIfNeed(cards, info[2])
        else
          table.insert(new_info, info)
        end
      end
      if #new_info == 0 then
        room:setPlayerMark(player, "qingya-turn", 0)
      else
        room:setPlayerMark(player, "qingya-turn", new_info)
      end
      cards = table.filter(cards, function (id)
        return table.contains(room.discard_pile, id)
      end)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = qingya.name,
      prompt = "#qingya-use",
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = cards,
      }
    })
  end,
})

return qingya
