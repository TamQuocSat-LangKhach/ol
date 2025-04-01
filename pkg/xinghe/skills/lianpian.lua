local lianpian = fk.CreateSkill{
  name = "lianpian",
}

Fk:loadTranslationTable{
  ["lianpian"] = "联翩",
  [":lianpian"] = "每回合限三次，当你于出牌阶段内使用牌指定目标后，若此牌与你此阶段内使用的上一张牌有共同的目标角色，你可以摸一张牌，"..
  "然后你可以摸到的牌交给这些角色中的一名。",

  ["#lianpian-choose"] = "联翩：你可以将%arg交给其中一名角色",

  ["$lianpian1"] = "需持续投入，方有回报。",
  ["$lianpian2"] = "心无旁骛，断而敢行！",
}

lianpian:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(lianpian.name) and player.phase == Player.Play and data.firstTarget and
      player:usedSkillTimes(lianpian.name, Player.HistoryTurn) < 3 then
      local room = player.room
      local tos
      if #room.logic:getEventsByRule(GameEvent.UseCard, 2, function (e)
        local use = e.data
        if use.from == player then
          tos = use.tos
          return true
        end
      end, nil, Player.HistoryPhase) < 2 then return end
      if not tos then return end
      local targets = table.filter(data.use.tos, function (p)
        return table.contains(tos, p)
      end)
      if #targets > 0 then
        event:setCostData(self, {extra_data = targets})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(1, lianpian.name)
    if player.dead then return end
    if table.contains(player:getCardIds("h"), cards[1]) then
      local targets = table.filter(event:getCostData(self).extra_data, function (p)
        return not p.dead and p ~= player
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = lianpian.name,
        prompt = "#lianpian-choose:::"..Fk:getCardById(cards[1]):toLogString(),
        cancelable = true,
      })
      if #to > 0 then
        room:moveCardTo(cards, Card.PlayerHand, to[1], fk.ReasonGive, lianpian.name, nil, false, player)
      end
    end
  end,
})

return lianpian
