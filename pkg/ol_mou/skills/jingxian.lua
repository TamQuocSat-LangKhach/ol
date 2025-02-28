local jingxian = fk.CreateSkill{
  name = "jingxian",
}

Fk:loadTranslationTable{
  ["jingxian"] = "敬贤",
  [":jingxian"] = "出牌阶段每名角色限一次，你可以交给其至多两张非基本牌，然后其选择等量项：1.其与你各摸一张牌；2.令你从牌堆中获得一张【杀】。",

  ["#jingxian"] = "敬贤：交给一名角色至多两张非基本牌，其选择等量项",
  ["jingxian1"] = "与 %src 各摸一张牌",
  ["jingxian2"] = "%src 获得一张【杀】",
}

jingxian:addEffect("active", {
  anim_type = "support",
  prompt = "#jingxian",
  min_card_num = 1,
  max_card_num = 2,
  target_num = 1,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not table.contains(player:getTableMark("jingxian-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "jingxian-phase", target.id)
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, jingxian.name, nil, false, player)
    if player.dead or target.dead then return end
    if #effect.cards == 2 then
      target:drawCards(1, jingxian.name)
      if player.dead then return end
      player:drawCards(1, jingxian.name)
      if player.dead then return end
      local cards = room:getCardsFromPileByRule("slash", 1, "drawPile")
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, jingxian.name, nil, true, player)
      end
    else
      local choice = room:askToChoice(target,{
        choices = {"jingxian1:"..player.id, "jingxian2:"..player.id},
        skill_name = jingxian.name,
      })
      if choice[9] == "1" then
        target:drawCards(1, jingxian.name)
        if player.dead then return end
        player:drawCards(1, jingxian.name)
      end
    end
  end,
})

return jingxian
