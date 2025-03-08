local tongdu = fk.CreateSkill{
  name = "ol__tongdu",
}

Fk:loadTranslationTable{
  ["ol__tongdu"] = "统度",
  [":ol__tongdu"] = "准备阶段，你可以令一名其他角色交给你一张手牌，然后本回合出牌阶段结束时，若此牌仍在你的手牌中，你将此牌置于牌堆顶。",

  ["#ol__tongdu-choose"] = "统度：令一名其他角色交给你一张手牌，出牌阶段结束时将之置于牌堆顶",
  ["#ol__tongdu-give"] = "统度：你须交给 %src 一张手牌",
  ["@@ol__tongdu-inhand-turn"] = "统度",

  ["$ol__tongdu1"] = "上下调度，臣工皆有所为。",
  ["$ol__tongdu2"] = "统筹部划，不糜国利分毫。",
}

tongdu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongdu.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = tongdu.name,
      prompt = "#ol__tongdu-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = tongdu.name,
      prompt = "#ol__tongdu-give:"..player.id,
      cancelable = false,
    })
    room:obtainCard(player, cards, false, fk.ReasonGive, to, tongdu.name, "@@ol__tongdu-inhand-turn")
  end,
})
tongdu:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and not player.dead and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@ol__tongdu-inhand-turn") > 0
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@ol__tongdu-inhand-turn") > 0
    end)
    room:moveCards({
      ids = cards,
      from = player,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = tongdu.name,
    })
  end,
})

return tongdu
