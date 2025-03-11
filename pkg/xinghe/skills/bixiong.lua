local bixiong = fk.CreateSkill{
  name = "bixiong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["bixiong"] = "避凶",
  [":bixiong"] = "锁定技，弃牌阶段结束时，若你于此阶段内弃置过手牌，直到你的下回合开始之前，你不是其他角色使用的与这些牌花色相同的牌的合法目标。",

  ["@bixiong"] = "避凶",

  ["$bixiong1"] = "避凶而从吉，以趋荆州。",
  ["$bixiong2"] = "逢凶化吉，遇难成祥。",
}

bixiong:addEffect(fk.EventPhaseEnd, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(bixiong.name) and player.phase == Player.Discard then
      local suits = {}
      local logic = player.room.logic
      logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                table.insertIfNeed(suits, Fk:getCardById(info.cardId):getSuitString(true))
              end
            end
          end
        end
      end, Player.HistoryTurn)
      table.removeOne(suits, "log_nosuit")
      if #suits > 0 then
        event:setCostData(self, {choice = suits})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local suits = event:getCostData(self).choice
    for _, suit in ipairs(suits) do
      player.room:addTableMarkIfNeed(player, "@bixiong", suit)
    end
  end,
})
bixiong:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@bixiong") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@bixiong", 0)
  end,
})
bixiong:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return from ~= to and card and table.contains(to:getTableMark("@bixiong"), card:getSuitString(true))
  end,
})

return bixiong
