local botu = fk.CreateSkill{ name = "ol_ex__botu" }

botu:addEffect(fk.TurnEnd,{
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name)
    and player:usedSkillTimes(self.name, Player.HistoryRound) < math.min(3, #player.room.alive_players)
    and type(player:getMark("@ol_ex__botu-turn")) == "table" and #player:getMark("@ol_ex__botu-turn") == 4
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn()
  end,
})

botu:addEffect(fk.TurnStart,{
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function (self, event, target, player, data)
    if player:hasSkill(self, true) then
      player.room:setPlayerMark(player, "@ol_ex__botu-turn", {})
    elseif player:usedSkillTimes(self.name, Player.HistoryRound) > 0 then
      player:setSkillUseHistory(self.name, 0, Player.HistoryRound)
    end
  end,
})

botu:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    if player.room.current == player then
      local mark = player:getMark("@ol_ex__botu-turn")
      if type(mark) == "table" then
        return #mark < 4
      else
        return player:hasSkill(self, true)
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local suitsRecorded = player:getTableMark("@ol_ex__botu-turn")
    local mark_change = false
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local suit = Fk:getCardById(info.cardId):getSuitString(true)
          if not table.contains(suitsRecorded, suit) then
            mark_change = true
            table.insert(suitsRecorded, suit)
          end
        end
      end
    end
    if mark_change then
      room:setPlayerMark(player, "@ol_ex__botu-turn", suitsRecorded)
    end
  end
})

Fk:loadTranslationTable {
  ["ol_ex__botu"] = "博图",
  [":ol_ex__botu"] = "每轮限X次（X为存活角色数且最多为3），回合结束时，若本回合内置入弃牌堆的牌包含四种花色，你可以获得一个额外回合。",

  ["@ol_ex__botu-turn"] = "博图",

  ["$ol_ex__botu1"] = "厚积而薄发。",
  ["$ol_ex__botu2"] = "我胸怀的是这天下！",
}

return botu
