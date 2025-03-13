local yuanlue = fk.CreateSkill{
  name = "yuanlue",
}

Fk:loadTranslationTable{
  ["yuanlue"] = "远略",
  [":yuanlue"] = "出牌阶段限一次，你可以交给一名其他角色一张非装备牌，然后其可以使用此牌，令你摸一张牌。",

  ["#yuanlue"] = "远略：交给一名角色一张非装备牌，其可以使用此牌，令你摸一张牌",
  ["#yuanlue-use"] = "远略：你可以使用这张牌，令 %src 摸一张牌",

  ["$yuanlue1"] = "若不引兵救乌巢，则主公危矣！",
  ["$yuanlue2"] = "此番攻之不破，吾属尽成俘虏。",
}

yuanlue:addEffect("active", {
  anim_type = "support",
  prompt = "#yuanlue",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yuanlue.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeEquip
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, yuanlue.name, nil, false, player)
    if not target.dead and table.contains(target:getCardIds("h"), effect.cards[1]) then
      if room:askToUseRealCard(target, {
        pattern = effect.cards,
        skill_name = yuanlue.name,
        prompt = "#yuanlue-use:"..player.id,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        }
      }) and not player.dead then
        player:drawCards(1, yuanlue.name)
      end
    end
  end,
})

return yuanlue
