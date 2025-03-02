local lizhan = fk.CreateSkill{
  name = "lizhan",
}

Fk:loadTranslationTable{
  ["lizhan"] = "励战",
  [":lizhan"] = "结束阶段，你可以令任意名已受伤的角色摸一张牌。",

  ["#lizhan-choose"] = "励战：你可以令任意名已受伤角色各摸一张牌",

  ["$lizhan1"] = "敌军围困万千重，我自岿然不动。",
  ["$lizhan2"] = "行伍严整，百战不殆。",
}

lizhan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lizhan.name) and player.phase == Player.Finish and
      table.find(player.room.alive_players, function(p)
        return p:isWounded()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 9,
      targets = table.filter(room.alive_players, function(p)
        return p:isWounded()
      end),
      skill_name = lizhan.name,
      prompt = "#lizhan-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        p:drawCards(1, lizhan.name)
      end
    end
  end,
})

return lizhan
