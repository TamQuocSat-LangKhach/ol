local lianzhu = fk.CreateSkill{
  name = "lianzhu",
}

Fk:loadTranslationTable{
  ["lianzhu"] = "连诛",
  [":lianzhu"] = "出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若该牌为黑色，其选择一项：1.你摸两张牌；2.弃置两张牌。",

  ["#lianzhu"] = "连诛：交给一名角色一张牌，若为黑色，其弃两张牌或令你摸两张牌",
  ["#lianzhu-discard"] = "连诛：你需弃置两张牌，否则 %src 摸两张牌",

  ["$lianzhu1"] = "若有不臣之心，定当株连九族。",
  ["$lianzhu2"] = "你们都是一条绳上的蚂蚱~",
}

lianzhu:addEffect("active", {
  anim_type = "control",
  prompt = "#lianzhu",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(lianzhu.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:showCards(effect.cards)
    if player.dead or not table.contains(player:getCardIds("h"), effect.cards[1]) then return end
    local card = Fk:getCardById(effect.cards[1])
    room:obtainCard(target, card, true, fk.ReasonGive, player, lianzhu.name)
    if card.color == Card.Black then
      if player.dead then
        room:askToDiscard(target, {
          min_num = 2,
          max_num = 2,
          include_equip = true,
          skill_name = lianzhu.name,
          cancelable = false,
        })
      elseif #target:getCardIds("he") < 2 or target.dead or
        #room:askToDiscard(target, {
          min_num = 2,
          max_num = 2,
          include_equip = true,
          skill_name = lianzhu.name,
          prompt = "#lianzhu-discard:"..player.id,
          cancelable = true,
        }) ~= 2 then
        player:drawCards(2, lianzhu.name)
      end
    end
  end,
})

return lianzhu
