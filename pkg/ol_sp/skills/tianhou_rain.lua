local rain = fk.CreateSkill{
  name = "tianhou_rain",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tianhou_rain"] = "骤雨",
  [":tianhou_rain"] = "锁定技，防止其他角色造成的火焰伤害。当一名角色受到雷电伤害后，其相邻的角色失去1点体力。",

  ["$tianhou_rain"] = "月离于毕，俾滂沱矣。",
}

rain:addAcquireEffect(function (self, player, is_start)
  player.room:setPlayerMark(player, "@@tianhou_rain", 1)
end)

rain:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@@tianhou_rain", 0)
end)

rain:addEffect(fk.DamageCaused, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(rain.name) and target ~= player and data.damageType == fk.FireDamage
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
  end,
})
rain:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(rain.name) and not (target.dead or target:isRemoved()) and data.damageType == fk.ThunderDamage and
      table.find(player.room.alive_players, function (p)
        return p ~= target and (p:getNextAlive() == target or target:getNextAlive() == p)
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return p ~= target and (p:getNextAlive() == target or target:getNextAlive() == p)
    end)
    room:doIndicate(player, targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:loseHp(p, 1, rain.name)
      end
    end
  end,
})

return rain
