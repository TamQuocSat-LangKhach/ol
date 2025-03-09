local yicheng = fk.CreateSkill{
  name = "yichengl",
}

Fk:loadTranslationTable{
  ["yichengl"] = "易城",
  [":yichengl"] = "出牌阶段限一次，你可以展示牌堆顶X张牌（X为你的体力上限），然后可以用任意张手牌交换其中等量张，"..
  "若展示牌点数之和因此增加，你可以用所有手牌交换展示牌。",

  ["#yichengl"] = "易城：展示牌堆顶%arg张牌，并可以用手牌交换其中的牌",
  ["#yichengl-exchange"] = "易城：你可以用任意张手牌替换等量的牌堆顶牌，点数和超过%arg可全部交换",
  ["#yichengl-exchange2"] = "易城：你可以用所有手牌交换展示的牌，请排列手牌在牌堆顶的位置",

  ["$yichengl1"] = "改帜易土，当奉玄德公为汝南之主。",
  ["$yichengl2"] = "地无常主，人有恒志，其择木而栖。",
}

Fk:addPoxiMethod{
  name = "yichengl",
  card_filter = function(to_select, selected, data)
    return table.contains(data[2], to_select)
  end,
  feasible = Util.TrueFunc,
}
yicheng:addEffect("active", {
  prompt = function(self, player)
    return "#yichengl:::"..player.maxHp
  end,
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(yicheng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = room:turnOverCardsFromDrawPile(player, room:getNCards(player.maxHp), yicheng.name)
    local n = 0
    for _, id in ipairs(cards) do
      n = n + Fk:getCardById(id).number
    end
    local cardmap = room:askToArrangeCards(player, {
      skill_name = yicheng.name,
      card_map = {
        "Top", cards,
        "$Hand", player:getCardIds("h"),
      },
      prompt = "#yichengl-exchange:::"..n,
      free_arrange = false,
    })
    local topile = table.filter(cardmap[1], function (id)
      return not table.contains(cards, id)
    end)
    if #topile > 0 then
      room:moveCardTo(topile, Card.Processing, nil, fk.ReasonJustMove, yicheng.name, nil, true, player)
      topile = table.filter(cards, function (id)
        return not table.contains(cardmap[1], id)
      end)
      if player.dead then
        room:cleanProcessingArea(topile)
        return
      else
        room:moveCardTo(topile, Card.PlayerHand, player, fk.ReasonJustMove, yicheng.name, nil, true, player)
        if not player.dead then
          for _, id in ipairs(cardmap[1]) do
            n = n - Fk:getCardById(id).number
          end
          if n < 0 then
            local top = room:askToArrangeCards(player, {
              skill_name = yicheng.name,
              card_map = {
                "Top", cardmap[1],
                "$Hand", player:getCardIds("h"),
              },
              prompt = "#yichengl-exchange2",
              free_arrange = false,
            })[2]
            if #top > 0 then
              room:returnCardsToDrawPile(player, top, yicheng.name)
              if player.dead then
                room:cleanProcessingArea(cardmap[1])
              else
                room:moveCardTo(cardmap[1], Card.PlayerHand, player, fk.ReasonJustMove, yicheng.name, nil, true, player)
              end
              return
            end
          end
        end
      end
    end
    room:returnCardsToDrawPile(player, cardmap[1], yicheng.name)
  end,
})

return yicheng
