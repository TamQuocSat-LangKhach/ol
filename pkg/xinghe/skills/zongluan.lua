local zongluan = fk.CreateSkill{
  name = "zongluan",
}

Fk:loadTranslationTable{
  ["zongluan"] = "纵乱",
  [":zongluan"] = "准备阶段，你可以选择一名角色，其视为使用一张可指定其攻击范围内的任意名角色为目标的【杀】，然后你弃置X张牌"..
  "（X为以此法受到伤害的角色数）。",

  ["#zongluan-choose"] = "纵乱：令一名角色视为对其攻击范围内任意名角色使用一张【杀】，你弃置受伤角色数的牌",
  ["#zongluan-slash"] = "纵乱：视为对攻击范围内任意名角色使用一张【杀】！",

  ["$zongluan1"] = "曹家车骑入徐，沿途卫所当便宜行事。",
  ["$zongluan2"] = "张闿何在？速去将曹老太爷礼送出境。",
}

zongluan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zongluan.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = zongluan.name,
      prompt = "#zongluan-choose",
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
    local card = Fk:cloneCard("slash")
    card.skillName = zongluan.name
    local targets = table.filter(room:getOtherPlayers(to, false), function (p)
      return to:inMyAttackRange(p) and to:canUseTo(card, p, {bypass_times = true})
    end)
    if #targets == 0 then return end
    local tos = room:askToChoosePlayers(to, {
      min_num = 1,
      max_num = 10,
      targets = room.alive_players,
      skill_name = zongluan.name,
      prompt = "#zongluan-slash",
      cancelable = false,
    })
    room:sortByAction(tos)
    local use = room:useVirtualCard("slash", nil, to, tos, zongluan.name, true)
    if use and use.damageDealt and not player.dead and not player:isNude() then
      local n = 0
      for _, p in ipairs(tos) do
        if use.damageDealt[p] then
          n = n + 1
        end
      end
      if n > 0 then
        room:askToDiscard(player, {
          min_num = n,
          max_num = n,
          include_equip = true,
          skill_name = zongluan.name,
          cancelable = false,
        })
      end
    end
  end,
})

return zongluan
