local zhaoran = fk.CreateSkill{
  name = "zhaoran",
}

Fk:loadTranslationTable{
  ["zhaoran"] = "昭然",
  [":zhaoran"] = "出牌阶段开始时，你可以令你的手牌本阶段对所有角色可见。若如此做，当你于本阶段失去任意花色的最后一张手牌后"..
  "（每种花色限一次），你摸一张牌或弃置一名其他角色的一张牌。",

  ["#zhaoran-invoke"] = "昭然：本阶段令你的手牌对所有角色可见，你失去一种花色最后的手牌后，摸一张牌或弃置一名角色一张牌",
  ["@zhaoran-phase"] = "昭然",
  ["#zhaoran-discard"] = "昭然：弃置一名其他角色一张牌，或点“取消”摸一张牌",

  ["$zhaoran1"] = "行昭然于世，赦众贼以威。",
  ["$zhaoran2"] = "吾之心思，路人皆知。",
}

zhaoran:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhaoran.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhaoran.name,
      prompt = "#zhaoran-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@zhaoran-phase", {})
  end,
})
zhaoran:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes(zhaoran.name, Player.HistoryPhase) > 0 and not player.dead then
      local mark = player:getTableMark("@zhaoran-phase")
      local suits = {}
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              local suit = Fk:getCardById(info.cardId):getSuitString(true)
              if not table.find(player:getCardIds("h"), function(id)
                return Fk:getCardById(id):getSuitString(true) == suit
              end) and
                not table.contains(mark, suit) then
                table.insertIfNeed(suits, suit)
              end
            end
          end
        end
      end
      table.insertTable(mark, suits)
      table.removeOne(suits, "log_nosuit")
      if #suits > 0 then
        player.room:setPlayerMark(player, "@zhaoran-phase", mark)
        event:setCostData(self, {extra_data = #suits})
        return true
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    local n = event:getCostData(self).extra_data
    for _ = 1, n do
      if player.dead then return end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhaoran.name,
      prompt = "#zhaoran-discard",
      cancelable = true,
    })
    if #to > 0 then
      local card = room:askToChooseCard(player, {
        target = to[1],
        flag = "he",
        skill_name = zhaoran.name,
      })
      room:throwCard(card, zhaoran.name, to[1], player)
    else
      player:drawCards(1, zhaoran.name)
    end
  end,
})
zhaoran:addEffect("visibility", {
  card_visible = function (self, player, card)
    local p = Fk:currentRoom().current
    if p and p.phase == Player.Play and p:usedSkillTimes(zhaoran.name, Player.HistoryPhase) > 0 and
      table.contains(p:getCardIds("h"), card.id) then
      return true
    end
  end,
})

return zhaoran
