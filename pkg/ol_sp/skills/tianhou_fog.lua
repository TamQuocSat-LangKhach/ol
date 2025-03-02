local fog = fk.CreateSkill{
  name = "tianhou_fog",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tianhou_fog"] = "凝雾",
  [":tianhou_fog"] = "锁定技，当其他角色使用【杀】指定不与其相邻的角色为唯一目标时，其判定，若判定牌点数大于此【杀】，此【杀】无效。",

  ["$tianhou_fog"] = "云雾弥野，如夜之幽。",
}

fog:addAcquireEffect(function (self, player, is_start)
  player.room:setPlayerMark(player, "@@tianhou_fog", 1)
end)

fog:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@@tianhou_fog", 0)
end)

fog:addEffect(fk.TargetSpecifying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(fog.name) and data.card.trueName == "slash" and
      #data.use.tos == 1 and data.to:getNextAlive() ~= target and target:getNextAlive() ~= data.to
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = data.card.number
    local pattern = ".|14"
    if n < 13 then
      pattern = ".|"..tostring(n + 1).."~13"
    end
    local judge = {
      who = target,
      reason = fog.name,
      pattern = pattern,
    }
    room:judge(judge)
    if judge:matchPattern() then
      data.nullified = true
    end
  end,
})

return fog
