local liewei = fk.CreateSkill{
  name = "ol__liewei",
}

Fk:loadTranslationTable{
  ["ol__liewei"] = "裂围",
  [":ol__liewei"] = "当你杀死一名角色时，你可以摸三张牌。",

  ["$ol__liewei1"] = "一息尚存，亦不容懈。",
  ["$ol__liewei2"] = "宰了你，可没有好处！",
}

liewei:addEffect(fk.Death, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(liewei.name) and data.killer == player
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, liewei.name)
  end,
})

return liewei
