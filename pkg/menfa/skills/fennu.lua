local fennu = fk.CreateSkill {
  name = "fennu",
}

Fk:loadTranslationTable{
  ["fennu"] = "奋驽",
  [":fennu"] = "出牌阶段开始时，你可以令至多X名角色各弃置一张牌，将这些牌置于你的武将牌上，称为“逸”（X为你当前体力值）。"..
  "若你武将牌上有“逸”，当你使用牌指定目标时，记录此牌的点数；准备阶段，若记录点数大于“逸”的点数和，你清除记录并获得所有“逸”。",

  ["#fennu-choose"] = "奋驽：令至多%arg名角色各弃置一张牌，你将这些牌置为“逸”",
  ["#fennu-discard"] = "奋驽：请弃置一张牌，%src 将之置为“逸”",
  ["#fennu"] = "逸",
  ["@[fennu]"] = "逸",
}

fennu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  derived_piles = "#fennu",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fennu.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:isNude()
    end)
    if table.contains(targets, player) and
      not table.find(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end) then
      table.removeOne(targets, player)
    end
    if #targets == 0 then
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = fennu.name,
        pattern = "false",
        prompt = "#fennu-choose:::"..player.hp,
        cancelable = true,
      })
    else
      local n = math.min(player.hp, #targets)
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = n,
        targets = targets,
        skill_name = fennu.name,
        prompt = "#fennu-choose:::"..n,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:sortByAction(event:getCostData(self).tos)
    local ids = {}
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead and not p:isNude() then
        local card = room:askToDiscard(p, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = fennu.name,
          cancelable = false,
          prompt = "#fennu-discard:"..player.id,
        })
        if #card > 0 then
          table.insertIfNeed(ids, card[1])
        end
      end
    end
    if player.dead then return end
    ids = table.filter(ids, function (id)
      return table.contains(room.discard_pile, id)
    end)
    if #ids == 0 then return end
    if player:hasSkill(fennu.name, true) then
      local mark = player:getMark("@[fennu]")
      if mark == 0 then
        mark = { value = {} }
      end
      table.insertTable(mark.value, ids)
      room:setPlayerMark(player, "@[fennu]", mark)
      player:addToPile("#fennu", ids, true, fennu.name, player)
    end
  end,
})

Fk:addQmlMark{
  name = "fennu",
  how_to_show = function(_, value, player)
    if type(value) ~= "table" then return " " end
    local n = 0
    for _, id in ipairs(player:getPile("#fennu")) do
      n = n + Fk:getCardById(id).number
    end
    return player:getMark(fennu.name).."/"..n
  end,
  qml_path = "packages/utility/qml/ViewPile"
}

fennu:addEffect(fk.TargetSpecifying, {
  anim_type = "special",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(fennu.name) and data.firstTarget and
      #player:getPile("#fennu") > 0 and data.card.number > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, fennu.name, data.card.number)
  end,
})

fennu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fennu.name) and player.phase == Player.Start and
      #player:getPile("#fennu") > 0 then
      local n = 0
      for _, id in ipairs(player:getPile("#fennu")) do
        n = n + Fk:getCardById(id).number
      end
      return player:getMark(fennu.name) > n
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, fennu.name, 0)
    room:setPlayerMark(player, "@[fennu]", 0)
    room:moveCardTo(player:getPile("#fennu"), Card.PlayerHand, player, fk.ReasonJustMove, fennu.name, nil, true, player)
  end,
})

fennu:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, fennu.name, 0)
  room:setPlayerMark(player, "@[fennu]", 0)
end)

return fennu
