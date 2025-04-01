local lianju = fk.CreateSkill{
  name = "lianju",
}

Fk:loadTranslationTable{
  ["lianju"] = "联句",
  [":lianju"] = "结束阶段，你可以令一名其他角色获得弃牌堆里你于本回合内使用过的至多两张颜色相同的牌，"..
  "然后其下个结束阶段，你可以获得弃牌堆中其于此回合内使用过的另一种颜色的至多两张牌。",

  ["#lianju-choose"] = "联句：你可以令一名其他角色获得你使用过的至多两张相同颜色的牌",
  ["#lianju-invoke"] = "联句：你可以获得 %dest 使用过的至多两张%arg牌",
  ["@lianju"] = "联句",

  ["$lianju1"] = "室中是阿谁？叹息声正悲。",
  ["$lianju2"] = "叹息亦何为？但恐大义亏。",
}

lianju:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(lianju.name) or target.dead or target.phase ~= Player.Finish then return false end
    local room = player.room
    if player == target then
      local cards = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == target then
          table.insertTableIfNeed(cards, Card:getIdList(use.card))
        end
      end, Player.HistoryTurn)
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    elseif table.contains(target:getTableMark("lianju_sources"), player.id) then
      local color = target:getMark("@lianju")
      local cards = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == target then
          table.insertTableIfNeed(cards, table.filter(Card:getIdList(use.card), function (id)
            return Fk:getCardById(id, true):getColorString() ~= color
          end))
        end
      end, Player.HistoryTurn)
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player == target then
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "lianju_active",
        prompt = "#lianju-choose",
        cancelable = true,
        extra_data = {
          expand_pile = event:getCostData(self).cards,
        },
      })
      if success and dat then
        event:setCostData(self, {tos = dat.targets, cards = dat.cards})
        return true
      end
    else
      event:setCostData(self, {tos = {target}, cards = event:getCostData(self).cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player == target then
      local to = event:getCostData(self).tos[1]
      local cards =  event:getCostData(self).cards
      room:setPlayerMark(to, "@lianju", Fk:getCardById(cards[1], true):getColorString())
      room:addTableMarkIfNeed(to, "lianju_sources", player.id)
      room:moveCardTo(cards, Player.Hand, to, fk.ReasonJustMove, lianju.name, nil, true, player,
        player:hasSkill("silv") and "@@silv" or nil)
    else
      local cards = event:getCostData(self).cards
      cards = room:askToCards(player, {
        min_num = 1,
        max_num = 2,
        include_equip = false,
        skill_name = lianju.name,
        pattern = tostring(Exppattern{ id = cards }),
        prompt = "#lianju-invoke::"..target.id..":"..Fk:getCardById(cards[1]):getColorString(),
        cancelable = true,
        expand_pile = cards,
      })
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, lianju.name, nil, true, player,
          player:hasSkill("silv") and "@@silv" or nil)
      end
    end
  end,
})
lianju:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@lianju") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@lianju", 0)
    player.room:setPlayerMark(player, "lianju_sources", 0)
  end,
})

return lianju
