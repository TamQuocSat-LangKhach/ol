local youji = fk.CreateSkill{
  name = "shengxiao_youji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shengxiao_youji"] = "酉鸡",
  [":shengxiao_youji"] = "锁定技，摸牌阶段，你多摸X张牌（X为游戏轮数且至多为5）。",
}

youji:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    data.n = data.n + math.min(5, player.room:getBanner("RoundCount"))
  end,
})

return youji
