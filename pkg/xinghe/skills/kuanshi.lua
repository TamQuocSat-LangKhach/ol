local kuanshi = fk.CreateSkill{
  name = "kuanshi",
}

Fk:loadTranslationTable{
  ["kuanshi"] = "宽释",
  [":kuanshi"] = "结束阶段，你可以选择一名角色。直到你的下回合开始，该角色下一次受到超过1点的伤害时，防止此伤害，然后你跳过下个回合的摸牌阶段。",

  ["#kuanshi-choose"] = "宽释：你可以选择一名角色，直到你下回合开始，防止其下次受到超过1点的伤害",
  ["@@kuanshi"] = "宽释",

  ["$kuanshi1"] = "不知者，无罪。",
  ["$kuanshi2"] = "罚酒三杯，下不为例。",
}

kuanshi:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuanshi.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = kuanshi.name,
      prompt = "#kuanshi-choose",
      cancelable = true,
      no_indicate = true
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, kuanshi.name, event:getCostData(self).tos[1].id)
  end,
})
kuanshi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and (player:getMark(kuanshi.name) ~= 0 or player:getMark("@@kuanshi") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, kuanshi.name, 0)
    if player:getMark("@@kuanshi") > 0 then
      player.room:setPlayerMark(player, kuanshi.name, 0)
      player:skip(Player.Draw)
    end
  end,
})
kuanshi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return data.damage > 1 and table.contains(player:getTableMark(kuanshi.name), target.id)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = target})
    return true
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
    player.room:removeTableMark(player, kuanshi.name, target.id)
    player.room:setPlayerMark(player, "@@kuanshi", 1)
  end,
})

return kuanshi
