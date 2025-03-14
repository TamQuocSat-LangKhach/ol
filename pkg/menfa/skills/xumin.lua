local xumin = fk.CreateSkill{
  name = "xumin",
  tags = { "Family" , Skill.Limited },
}

Fk:loadTranslationTable{
  ["xumin"] = "恤民",
  [":xumin"] = "宗族技，限定技，出牌阶段，你可以将一张牌当【五谷丰登】对任意名其他角色使用。",

  ["#xumin"] = "恤民：你可以将一张牌当【五谷丰登】对任意名其他角色使用",
}

xumin:addEffect("active", {
  anim_type = "support",
  prompt = "#xumin",
  card_num = 1,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xumin.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:cloneCard("amazing_grace")
    card:addSubcard(to_select)
    card.skillName = xumin.name
    return player:canUse(card) and not player:prohibitUse(card)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards == 0 or to_select == player then return end
    local card = Fk:cloneCard("amazing_grace")
    card:addSubcards(selected_cards)
    card.skillName = xumin.name
    return not player:isProhibited(to_select, card)
  end,
  on_use = function(self, room, effect)
    room:useVirtualCard("amazing_grace", effect.cards, effect.from, effect.tos, xumin.name)
  end,
})

return xumin
