local mingzhe = fk.CreateSkill{
  name = "ol__mingzhe",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__mingzhe"] = "明哲",
  [":ol__mingzhe"] = "锁定技，当你于出牌阶段外失去红色牌后，你摸一张牌；若这些牌在其他角色手牌区，你令这些角色各展示之。",

  ["$ol__mingzhe1"] = "乱世，当稳中求胜。",
  ["$ol__mingzhe2"] = "明哲维天，临君下土。",
}

mingzhe:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(mingzhe.name) and player.phase ~= Player.Play then
      for _, move in ipairs(data) do
        if move.from == player and (move.to ~= player or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              Fk:getCardById(info.cardId, true).color == Card.Red then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, move in ipairs(data) do
      if move.from == player and (move.to ~= player or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            Fk:getCardById(info.cardId, true).color == Card.Red and room:getCardArea(info.cardId) == Card.PlayerHand then
            table.insert(cards, info.cardId)
          end
        end
      end
    end
    if #cards > 0 then
      for _, p in ipairs(player.room.alive_players) do
        local to_show = table.filter(cards, function(id)
          return room:getCardOwner(id) == p
        end)
        if #to_show > 0 then
          p:showCards(to_show)
        end
      end
    end
    player:drawCards(1, mingzhe.name)
  end,
})

return mingzhe
