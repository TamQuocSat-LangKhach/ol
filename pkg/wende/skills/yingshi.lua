local yingshi = fk.CreateSkill{
  name = "yingshis",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yingshis"] = "鹰视",
  [":yingshis"] = "锁定技，牌堆顶的X张牌于你出牌阶段空闲时对你可见（X为你的体力上限）。",

  ["$yingshis1"] = "鹰扬千里，明察秋毫。",
  ["$yingshis2"] = "鸢飞戾天，目入百川。",
}

yingshi:addEffect("active", {
  anim_type = "control",
  card_num = 999,
  target_num = 0,
  expand_pile = function(self, player)
    local ids = {}
    for i = 1, player.maxHp, 1 do
      if i > #Fk:currentRoom().draw_pile then break end
      table.insert(ids, Fk:currentRoom().draw_pile[i])
    end
    return ids
  end,
  card_filter = Util.FalseFunc,
  can_use = Util.TrueFunc,
})

return yingshi
