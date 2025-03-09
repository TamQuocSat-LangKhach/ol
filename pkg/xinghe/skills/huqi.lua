local huqi = fk.CreateSkill{
  name = "huqi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["huqi"] = "虎骑",
  [":huqi"] = "锁定技，你计算与其他角色的距离-1；当你于回合外受到伤害后，你进行判定，若结果为红色，视为你对伤害来源使用一张【杀】（无距离限制）。",

  ["$huqi1"] = "骑虎云游，探求道法。",
  ["$huqi2"] = "求仙长生，感悟万象。",
}

huqi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huqi.name) and player.room.current ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = huqi.name,
      pattern = ".|.|heart,diamond",
    }
    room:judge(judge)
    if judge:matchPattern() and data.from and not data.from.dead and data.from ~= player then
      room:useVirtualCard("slash", nil, player, data.from, huqi.name, true)
    end
  end,
})
huqi:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(huqi.name) then
      return -1
    end
  end,
})

return huqi
