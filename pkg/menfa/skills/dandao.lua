local dandao = fk.CreateSkill{
  name = "dandao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dandao"] = "耽道",
  [":dandao"] = "锁定技，当你判定后，当前回合角色本回合手牌上限+3。",

  ["$dandao1"] = "",
  ["$dandao2"] = "",
}

dandao:addEffect(fk.FinishJudge, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dandao.name) and
      not player.room.current.dead and player.room.current.phase ~= Player.NotActive
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {player.room.current}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(room.current, MarkEnum.AddMaxCardsInTurn, 3)
  end,
})

return dandao