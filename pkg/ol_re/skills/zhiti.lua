local zhiti = fk.CreateSkill{
  name = "ol__zhiti",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__zhiti"] = "止啼",
  [":ol__zhiti"] = "锁定技，你攻击范围内已受伤的角色手牌上限-1；若场上已受伤的角色数不小于：1，你的手牌上限+1；3，摸牌阶段，你多摸一张牌；"..
  "5，结束阶段，你可以废除一名角色一个随机的装备栏。",

  ["#ol__zhiti-choose"] = "止啼：你可以废除一名角色的随机一个装备栏",

  ["$ol__zhiti1"] = "凌烟常忆张文远，逍遥常哭孙仲谋！",
  ["$ol__zhiti2"] = "吾名如良药，可医吴儿夜啼！",
}

zhiti:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhiti.name) and player.phase == Player.Finish and
      #table.filter(player.room.alive_players, function (p)
        return p:isWounded()
      end) > 4 and
      table.find(player.room.alive_players, function (p)
        return #p:getAvailableEquipSlots() > 0
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return #p:getAvailableEquipSlots() > 0
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhiti.name,
      prompt = "#ol__zhiti-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local slot = table.random(to:getAvailableEquipSlots())
    if slot == Player.OffensiveRideSlot or Player.DefensiveRideSlot then
      slot = {Player.OffensiveRideSlot, Player.DefensiveRideSlot}
    end
    room:abortPlayerArea(to, slot)
  end,
})
zhiti:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhiti.name) and
      #table.filter(player.room.alive_players, function(p)
        return p:isWounded()
      end) > 2
  end,
  on_use = function (self, event, target, player, data)
    data.n = data.n + 1
  end,
})
zhiti:addEffect("maxcards", {
  correct_func = function(self, player)
    local n = 0
    local players = Fk:currentRoom().alive_players
    if player:hasSkill(zhiti.name) and table.find(players, function (p)
      return p:isWounded()
    end) then
      n = 1
    end
    if player:isWounded() then
      for _, p in ipairs(players) do
        if p:hasSkill(zhiti.name) and p:inMyAttackRange(player) then
          n = n - 1
        end
      end
    end
    return n
  end,
})

return zhiti
