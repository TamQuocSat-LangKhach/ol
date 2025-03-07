local gongjie = fk.CreateSkill{
  name = "gongjie",
}

Fk:loadTranslationTable{
  ["gongjie"] = "恭节",
  [":gongjie"] = "每轮的第一个回合开始时，你可以令任意名其他角色各获得你一张牌，然后你摸X张牌（X为被获得牌的花色数）。",

  ["#gongjie-choose"] = "恭节：你可以令任意名角色各获得你一张牌，然后你摸被获得花色数的牌",

  ["$gongjie1"] = "身负浩然之气，当以恭节待人。",
  ["$gongjie2"] = "生于帝王之家，不可忘恭失节。",
}

gongjie:addEffect(fk.TurnStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gongjie.name) and not player:isNude() and
      #player.room.logic:getEventsOfScope(GameEvent.Turn, 2, Util.TrueFunc, Player.HistoryRound) == 1 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = #player:getCardIds("he"),
      targets = room:getOtherPlayers(player, false),
      skill_name = gongjie.name,
      prompt = "#gongjie-choose",
      cancelable = true,
    })
    if #tos > 0 then
      local new_tos = {}
      local p = player:getNextAlive()
      while p ~= player do
        if table.contains(tos, p) then
          table.insert(new_tos, p)
        end
        p = p:getNextAlive()
      end
      event:setCostData(self, {tos = new_tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(event:getCostData(self).tos)
    local mark = player:getTableMark("gongjie_targets")
    table.insertTableIfNeed(mark, table.map(targets, Util.IdMapper))
    room:setPlayerMark(player, "gongjie_targets", mark)
    local suits = {}
    for _, p in ipairs(targets) do
      if player.dead or player:isNude() then break end
      if not p.dead then
        local id = room:askToChooseCard(p, {
          target = player,
          flag = "he",
          skill_name = gongjie.name,
        })
        local suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(suits, suit)
        end
        room:obtainCard(p, id, false, fk.ReasonPrey, p, gongjie.name)
      end
    end
    if not player.dead and #suits > 0 then
      player:drawCards(#suits, gongjie.name)
    end
  end,
})

return gongjie
