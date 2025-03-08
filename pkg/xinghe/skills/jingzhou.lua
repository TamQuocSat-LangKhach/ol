local jingzhou = fk.CreateSkill{
  name = "jingzhou",
}

Fk:loadTranslationTable{
  ["jingzhou"] = "精舟",
  [":jingzhou"] = "当你受到伤害时，你可以令至多X名角色改变“连环状态”。（X为你的体力值）",

  ["#jingzhou-choose"] = "精舟：你可以选择至多%arg名角色，改变这些角色的“连环状态”",

  ["$jingzhou1"] = "艨艟连江，敌必不战自退。",
  ["$jingzhou2"] = "精舟锐进，直捣孙家老巢。",
}

jingzhou:addEffect(fk.DamageInflicted, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jingzhou.name) and player.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = player.hp,
      targets = room.alive_players,
      skill_name = jingzhou.name,
      prompt = "#jingzhou-choose:::"..player.hp,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local tos = table.simpleClone(event:getCostData(self).tos)
    for _, to in ipairs(tos) do
      if not to.dead then
        to:setChainState(not to.chained)
      end
    end
  end,
})

return jingzhou
