local qiongshou = fk.CreateSkill{
  name = "qiongshou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qiongshou"] = "穷守",
  [":qiongshou"] = "锁定技，游戏开始时，你废除所有装备栏并摸四张牌。你的手牌上限+4。",

  ["$qiongshou1"] = "戍守孤城，其势不侵。",
  ["$qiongshou2"] = "吾头可得，而城不可得。",
}

qiongshou:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qiongshou.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:abortPlayerArea(player, player:getAvailableEquipSlots())
    if player.dead then return end
    player:drawCards(4, qiongshou.name)
  end,
})
qiongshou:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(qiongshou.name) then
      return 4
    end
  end,
})

return qiongshou
