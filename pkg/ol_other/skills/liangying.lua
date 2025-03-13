local liangying = fk.CreateSkill{
  name = "guandu__liangying",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guandu__liangying"] = "粮营",
  [":guandu__liangying"] = "锁定技，若你有“粮”，群势力角色摸牌阶段多摸一张牌；当你失去所有“粮”时，你减1点体力上限，然后魏势力角色各摸一张牌。",
}

liangying:addEffect(fk.DrawNCards, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(liangying.name) and target.kingdom == "qun" and
      player:getMark("@guandu_grain") > 0 and not target.dead
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    data.n = data.n + 1
  end,
})
liangying:addEffect(fk.AfterSkillEffect, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(liangying.name) and
      data.skill.name == "guandu__cangchu" and player:getMark("@guandu_grain") == 0 and
      table.find(player.room.alive_players, function (p)
        return p.kingdom == "wei"
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function (p)
      return p.kingdom == "wei"
    end)
    event:setCostData(self, {tos = targets})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p.kingdom == "wei" and not p.dead then
        p:drawCards(1, liangying.name)
      end
    end
  end,
})

return liangying
