local fenchai = fk.CreateSkill{
  name = "fenchai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fenchai"] = "分钗",
  [":fenchai"] = "锁定技，若首次成为你技能目标的异性角色存活，你的判定牌视为<font color='red'>♥</font>，否则视为♠。",

  ["$fenchai1"] = "钗同我心，奈何分之？",
  ["$fenchai2"] = "夫妻分钗，天涯陌路。",
}

fenchai:addEffect("filter", {
  card_filter = function(self, to_select, player, isJudgeEvent)
    return player:hasSkill(fenchai.name) and player:getMark(fenchai.name) ~= 0 and isJudgeEvent
  end,
  view_as = function(self, player, to_select)
    local suit = Card.Heart
    if player:getMark(fenchai.name) ~= 0 and Fk:currentRoom():getPlayerById(player:getMark(fenchai.name)).dead then
      suit = Card.Spade
    end
    return Fk:cloneCard(to_select.name, suit, to_select.number)
  end,
})

return fenchai
