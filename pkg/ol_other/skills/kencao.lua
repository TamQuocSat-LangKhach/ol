local kencao = fk.CreateSkill{
  name = "qin__kencao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__kencao"] = "垦草",
  [":qin__kencao"] = "锁定技，每当秦势力角色造成1点伤害后，其获得一枚“功”标记，然后若其“功”标记不小于3，其弃置所有“功”标记，加1点体力上限，"..
  "回复1点体力。",

  ["@qin__kencao"] = "功",

  ["$qin__kencao"] = "农静，诛愚；乱农之民欲农，则草必垦矣。",
}

kencao:addLoseEffect(function (self, player)
  local room = player.room
  if not table.find(room.alive_players, function (p)
    return p:hasSkill(kencao.name)
  end) then
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@qin__kencao", 0)
    end
  end
end)

kencao:addEffect(fk.Damage, {
  anim_type = "support",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kencao.name) and target and target.kingdom == "qin" and not target.dead
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(target, "@qin__kencao", 1)
    if target:getMark("@qin__kencao") > 2 then
      room:setPlayerMark(target, "@qin__kencao", 0)
      room:changeMaxHp(target, 1)
      if target:isWounded() and not target.dead then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = kencao.name,
        }
      end
    end
  end,
})

return kencao
