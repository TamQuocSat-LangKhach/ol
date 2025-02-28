local botu = fk.CreateSkill{
  name = "botu",
}

Fk:loadTranslationTable {
  ["botu"] = "博图",
  [":botu"] = "每轮限X次（X为存活角色数且最多为3），回合结束时，若本回合内置入弃牌堆的牌包含四种花色，你可以获得一个额外回合。",

  ["@botu-turn"] = "博图",

  ["$botu1"] = "厚积而薄发。",
  ["$botu2"] = "我胸怀的是这天下！",
}

botu:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(botu.name) and
      player:usedSkillTimes(botu.name, Player.HistoryRound) < math.min(3, #player.room.alive_players) then
      local suits = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(suits, Fk:getCardById(info.cardId).suit)
            end
          end
        end
      end, Player.HistoryTurn)
      table.removeOne(suits, Card.NoSuit)
      return #suits == 4
    end
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn()
  end,
})

botu:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player.room.current == player and player:hasSkill(botu.name, true) and
      #player:getTableMark("@botu-turn") < 4
  end,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local suit = Fk:getCardById(info.cardId):getSuitString(true)
          if suit ~= "log_nosuit" then
            player.room:addTableMarkIfNeed(player, "@botu-turn", suit)
          end
        end
      end
    end
  end
})

return botu
