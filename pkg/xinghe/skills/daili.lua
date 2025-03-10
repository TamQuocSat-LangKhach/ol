local daili = fk.CreateSkill{
  name = "daili",
}

Fk:loadTranslationTable{
  ["daili"] = "带砺",
  [":daili"] = "每回合结束时，若你有偶数张展示过的手牌，你可以翻面，摸三张牌并展示之。",

  ["@$daili"] = "带砺",
  ["@@daili"] = "带砺",

  ["$daili1"] = "国朝倾覆，吾宁当为降虏乎！",
  ["$daili2"] = "弃百姓之所仰，君子不为也。",
}

daili:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(daili.name) and (player:isKongcheng() or
      #table.filter(player:getCardIds("h"), function(id) return
        Fk:getCardById(id):getMark("@@daili") > 0
      end) % 2 == 0)
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    if player.dead then return end
    local cards = player:drawCards(3, daili.name)
    if player.dead then return end
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards > 0 then
      player:showCards(cards)
    end
  end,
})
daili:addEffect(fk.CardShown, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(daili.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@$daili")
    for _, id in ipairs(data.cardIds) do
      if Fk:getCardById(id):getMark("@@daili") == 0 and table.contains(player:getCardIds("h"), id) then
        table.insert(mark, id)
        room:setCardMark(Fk:getCardById(id, true), "@@daili", 1)
      end
    end
    room:setPlayerMark(player, "@$daili", mark)
  end,
})
daili:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@$daili") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@$daili")
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId, true):getMark("@@daili") > 0 then
            table.removeOne(mark, info.cardId)
            room:setCardMark(Fk:getCardById(info.cardId, true), "@@daili", 0)
          end
        end
      end
    end
    room:setPlayerMark(player, "@$daili", mark)
  end,
})

return daili
