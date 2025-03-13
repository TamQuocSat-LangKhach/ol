local shihuang = fk.CreateSkill{
  name = "qin__shihuang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__shihuang"] = "始皇",
  [":qin__shihuang"] = "锁定技，其他角色回合结束时，你有X%几率获得一个额外回合（X为游戏轮数的6倍）。",

  ["$qin__shihuang"] = "吾，才是万世的开始！",
}

shihuang:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shihuang.name) and target ~= player and
      math.random() < (6 * player.room:getBanner("RoundCount") / 100)
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn(true, shihuang.name)
  end,
})

return shihuang
