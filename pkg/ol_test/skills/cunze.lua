local cunze = fk.CreateSkill{
  name = "cunze",
}

Fk:loadTranslationTable{
  ["cunze"] = "存择",
  [":cunze"] = "结束阶段，你可以秘密选择一名角色。直到你下回合开始，该角色首次进入濒死状态时，其回复体力至1点，然后你不能使用【桃】直到你下回合开始。",

  ["#cunze-choose"] = "存择：秘密选择一名角色，直到你下回合开始，其首次进入濒死状态时回复体力至1点",
  ["@@cunze"] = "存择",

  ["$cunze1"] = "",
  ["$cunze2"] = "",
}

cunze:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cunze.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = cunze.name,
      prompt = "#cunze-choose",
      cancelable = true,
      no_indicate = true
    })
    if #to > 0 then
      event:setCostData(self, {extra_data = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, cunze.name, event:getCostData(self).extra_data[1].id)
  end,
})

cunze:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, cunze.name, 0)
    room:setPlayerMark(player, "@@cunze", 0)
  end,
})

cunze:addEffect(fk.EnterDying, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return table.contains(player:getTableMark(cunze.name), target.id) and not target.dead
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, cunze.name, target.id)
    room:setPlayerMark(player, "@@cunze", 1)
    room:recover{
      who = target,
      num = 1 - target.hp,
      recoverBy = player,
      skillName = cunze.name,
    }
  end,
})

return cunze
