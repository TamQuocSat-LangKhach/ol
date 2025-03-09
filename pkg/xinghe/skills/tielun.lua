local tielun = fk.CreateSkill{
  name = "tielun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tielun"] = "铁轮",
  [":tielun"] = "锁定技，你计算至其他角色的距离-X（X为你于此轮内使用过的牌数）。",

  ["@tielun-round"] = "铁轮",
}

tielun:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(tielun.name) then
      return -from:getMark("@tielun-round")
    end
  end,
})
tielun:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(tielun.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@tielun-round")
  end,
})

return tielun
