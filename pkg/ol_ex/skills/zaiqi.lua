local zaiqi = fk.CreateSkill{
  name = "ol_ex__zaiqi",
}

Fk:loadTranslationTable {
  ["ol_ex__zaiqi"] = "再起",
  [":ol_ex__zaiqi"] = "弃牌阶段结束时，你可以选择至多X名角色（X为本回合进入弃牌堆红色牌数），这些角色依次选择一项：1.令你回复1点体力；2.摸一张牌。",

  ["#ol_ex__zaiqi-choose"] = "再起：选择至多%arg名角色，这些角色各选择令你回复1点体力或摸一张牌",
  ["ol_ex__zaiqi_recover"] = "%src回复1点体力",

  ["$ol_ex__zaiqi1"] = "挫而弥坚，战而弥勇！",
  ["$ol_ex__zaiqi2"] = "蛮人骨硬，其势复来！",
}

zaiqi:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zaiqi.name) and player.phase == Player.Discard then
      local ids = {}
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return false end
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end, turn_event.id)
      local x = #table.filter(ids, function (id)
        return Fk:getCardById(id).color == Card.Red
      end)
      if x > 0 then
        event:setCostData(self, {extra_data = x})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = event:getCostData(self).extra_data
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = x,
      prompt = "#ol_ex__zaiqi-choose:::"..x,
      skill_name = zaiqi.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    for _, p in ipairs(targets) do
      if not p.dead then
        local choices = {"draw1"}
        if not player.dead and player:isWounded() then
          table.insert(choices, "ol_ex__zaiqi_recover:"..player.id)
        end
        local choice = room:askToChoice(p, {
          choices = choices,
          skill_name = zaiqi.name,
        })
        if choice == "draw1" then
          p:drawCards(1, zaiqi.name)
        else
          room:recover{
            who = player,
            num = 1,
            recoverBy = p,
            skillName = zaiqi.name,
          }
        end
      end
    end
  end,
})

return zaiqi