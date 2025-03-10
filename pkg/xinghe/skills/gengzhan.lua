local gengzhan = fk.CreateSkill{
  name = "gengzhan",
}

Fk:loadTranslationTable{
  ["gengzhan"] = "更战",
  [":gengzhan"] = "其他角色的出牌阶段内限一次，当一张【杀】因弃置而进入弃牌堆后，你可以获得之。其他角色的结束阶段，若其本回合未使用过【杀】，"..
  "你下个出牌阶段使用【杀】次数+1。",

  ["@gengzhan-phase"] = "更战",
  ["@gengzhan_record"] = "更战",

  ["$gengzhan1"] = "将无常败，军可常胜。",
  ["$gengzhan2"] = "前进可活，后退即死。",
}

gengzhan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gengzhan.name) and target ~= player and target.phase == Player.Finish and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.from == target and use.card.trueName == "slash"
      end, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@gengzhan_record")
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("@gengzhan_record") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@gengzhan-phase", player:getMark("@gengzhan_record"))
    room:setPlayerMark(player, "@gengzhan_record", 0)
  end,
})
gengzhan:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@gengzhan-phase") > 0 and scope == Player.HistoryPhase then
      return player:getMark("@gengzhan-phase")
    end
  end,
})
gengzhan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(gengzhan.name) and player.room.current ~= player and
      player.room.current.phase == Player.Play and
      player:usedEffectTimes(self.name, Player.HistoryPhase) == 0 then
      local ids = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).trueName == "slash" and table.contains(player.room.discard_pile, info.cardId) then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
      if #ids > 0 then
        event:setCostData(self, {cards = ids})
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    if #cards > 1 then
      cards = room:askToChooseCard(player, {
        target = player,
        flag = { card_data = {{ "slash", cards }} },
        skill_name = gengzhan.name,
      })
    end
    room:obtainCard(player, cards, true, fk.ReasonJustMove, player, gengzhan.name)
  end,
})

return gengzhan
