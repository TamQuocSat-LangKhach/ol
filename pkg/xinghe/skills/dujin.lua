local dujin = fk.CreateSkill{
  name = "ol__dujin",
}

Fk:loadTranslationTable{
  ["ol__dujin"] = "独进",
  [":ol__dujin"] = "摸牌阶段，你可以多摸X+1张牌（X为装备区里的牌数的一半且向上取整）。",

  ["$ol__dujin1"] = "轻舟独进，看我先登破城！",
  ["$ol__dujin2"] = "身先于众将，独揽此大功！",
}

dujin:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1 + (1 + #player:getCardIds("e")) // 2
  end,
})

return dujin
