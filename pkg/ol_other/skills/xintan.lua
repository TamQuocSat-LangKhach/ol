local xintan = fk.CreateSkill{
  name = "xintan",
}

Fk:loadTranslationTable{
  ["xintan"] = "心惔",
  [":xintan"] = "出牌阶段限一次，你可以将两张“焚”置入弃牌堆，令一名角色失去1点体力。",

  ["#xintan"] = "心惔：将两张“焚”置入弃牌堆，令一名角色失去1点体力",

  ["$xintan1"] = "让心中之火慢慢吞噬你吧！哈哈哈哈哈哈！",
  ["$xintan2"] = "人人心中都有一团欲望之火！",
}

xintan:addEffect("active", {
  prompt = "#xintan",
  anim_type = "offensive",
  card_num = 2,
  target_num = 1,
  expand_pile = "fentian_burn",
  can_use = function(self, player)
    return #player:getPile("fentian_burn") > 1 and player:usedSkillTimes(xintan.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected_cards == 2 and #selected == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and table.contains(player:getPile("fentian_burn"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, xintan.name, nil, true, player)
    if not target.dead then
      room:loseHp(target, 1, xintan.name)
    end
  end,
})

return xintan
