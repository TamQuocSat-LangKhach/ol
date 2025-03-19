local qimei = fk.CreateSkill{
  name = "qimei",
}

Fk:loadTranslationTable{
  ["qimei"] = "齐眉",
  [":qimei"] = "准备阶段，你可以选择一名其他角色，直到你的下个回合开始（每回合每项限一次），当你或该角色的手牌数或体力值变化后，"..
  "若双方的此数值相等，另一方摸一张牌。",

  ["#qimei-choose"] = "齐眉：指定一名其他角色为“齐眉”角色，双方手牌数或体力值变化为相等时可以摸牌",
  ["@@qimei"] = "齐眉",

  ["$qimei1"] = "辅车相依，比翼双飞。",
  ["$qimei2"] = "情投意合，相濡以沫。",
}

qimei:addLoseEffect(function (self, player, is_death)
  if is_death and player:getMark("qimei_couple") ~= 0 then
    local room = player.room
    local to = room:getPlayerById(player:getMark("qimei_couple"))
    room:setPlayerMark(player, "qimei_couple", 0)
    room:removeTableMark(to, "@@qimei", player.id)
  end
end)

qimei:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qimei.name) and player.phase == Player.Start and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = qimei.name,
      prompt = "#qimei-choose",
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
    room:addTableMark(to, "@@qimei", player.id)
    room:setPlayerMark(player, "qimei_couple", to.id)
  end,
})
qimei:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark("qimei_couple") == 0 or player.dead or
      player:usedEffectTimes(self.name, Player.HistoryTurn) > 0 then return end
    local room = player.room
    local to = room:getPlayerById(player:getMark("qimei_couple"))
    if to.dead or player:getHandcardNum() ~= to:getHandcardNum() then return end
    local tos = {player, to}
    for _, move in ipairs(data) do
      if table.contains(tos, move.from) and
        table.find(move.moveInfo, function (info)
          return info.fromArea == Card.PlayerHand
        end) then
        table.removeOne(tos, move.from)
      end
      if move.to and table.contains(tos, move.to) and move.toArea == Card.PlayerHand then
        table.removeOne(tos, move.to)
      end
    end
    if #tos == 2 then return end
    if #tos == 0 then
      tos = {player, to}
    end
    room:sortByAction(tos)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function (self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, qimei.name)
  end,
})
qimei:addEffect(fk.HpChanged, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark("qimei_couple") == 0 or player.dead or
      player:usedEffectTimes(self.name, Player.HistoryTurn) > 0 then return end
    local room = player.room
    local to = room:getPlayerById(player:getMark("qimei_couple"))
    if to.dead or player.hp ~= to.hp then return end
    if target == player then
      event:setCostData(self, {tos = {to}})
      return true
    elseif target == to then
      event:setCostData(self, {tos = {player}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, qimei.name)
  end,
})
qimei:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("qimei_couple") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("qimei_couple"))
    room:setPlayerMark(player, "qimei_couple", 0)
    room:removeTableMark(to, "@@qimei", player.id)
  end,
})

return qimei
