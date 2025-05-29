local goude = fk.CreateSkill{
  name = "goude",
}

Fk:loadTranslationTable{
  ["goude"] = "苟得",
  [":goude"] = "每回合结束时，若有势力相同的角色此回合执行过以下效果，你可以执行另一项：1.摸一张牌；2.弃置一名角色一张手牌；"..
  "3.视为使用一张【杀】；4.变更势力。",

  ["#goude-choice"] = "苟得：你可以选择执行一项",
  ["goude2"] = "弃置一名角色一张手牌",
  ["goude3"] = "视为使用一张【杀】",
  ["goude4"] = "变更势力",
  ["#goude-choose"] = "苟得：选择一名角色，弃置其一张手牌",
  ["#goude-slash"] = "苟得：视为使用一张【杀】",

  ["$goude1"] = "蝼蚁尚且偷生，况我大将军乎。",
  ["$goude2"] = "为保身家性命，做奔臣又如何？",
}

goude:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(goude.name) then
      local room = player.room
      for _, p in ipairs(room.alive_players) do
        if p.kingdom == player.kingdom then
          local events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
            for _, move in ipairs(e.data) do
              if move.to == p and move.moveReason == fk.ReasonDraw and #move.moveInfo == 1 then
                return true
              elseif move.moveReason == fk.ReasonDiscard and move.proposer == p and #move.moveInfo == 1 then
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.PlayerHand then
                    return true
                  end
                end
              end
            end
          end, Player.HistoryTurn)
          if #events > 0 then return true end
          events = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
            local use = e.data
            return use.from == p and use.card.trueName == "slash" and #Card:getIdList(use.card) == 0
          end, Player.HistoryTurn)
          if #events > 0 then return true end
          events = room.logic:getEventsOfScope(GameEvent.ChangeProperty, 1, function(e)
            local dat = e.data
            return dat.from == p and dat.results and dat.results["kingdomChange"]
          end, Player.HistoryTurn)
          if #events > 0 then return true end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1", "goude2", "goude3", "goude4", "Cancel"}
    if table.every(room.alive_players, function(p)
      return p:isKongcheng()
    end) then
      table.removeOne(choices, "goude2")
    end
    for _, p in ipairs(room.alive_players) do
      if p.kingdom == player.kingdom then
        local events
        if table.contains(choices, "draw1") then
          events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
            for _, move in ipairs(e.data) do
              if move.to == p and move.moveReason == fk.ReasonDraw and #move.moveInfo == 1 then
                return true
              end
            end
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "draw1")
          end
        end
        if table.contains(choices, "goude2") then
          events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
            for _, move in ipairs(e.data) do
              if move.moveReason == fk.ReasonDiscard and move.proposer == p and #move.moveInfo == 1 then
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.PlayerHand then
                    return true
                  end
                end
              end
            end
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "goude2")
          end
        end
        if table.contains(choices, "goude3") then
          events = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
            local use = e.data
            return use.from == p and use.card.trueName == "slash" and #Card:getIdList(use.card) == 0
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "goude3")
          end
        end
        if table.contains(choices, "goude4") then
          events = room.logic:getEventsOfScope(GameEvent.ChangeProperty, 1, function(e)
            local dat = e.data
            return dat.from == p and dat.results and dat.results["kingdomChange"]
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "goude4")
          end
        end
      end
    end
    if #choices == 1 then return end
    local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = goude.name,
        prompt = "#goude-choice",
        all_choices = {"draw1", "goude2", "goude3", "goude4", "Cancel"},
      })
    if choice == "draw1" or choice == "goude4" then
      event:setCostData(self, {choice = choice})
      return true
    elseif choice == "goude2" then
      local targets = table.filter(room.alive_players, function(p)
        return not p:isKongcheng()
      end)
      if not table.find(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id)
      end) then
        table.removeOne(targets, player)
      end
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = goude.name,
        prompt = "#goude-choose",
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to, choice = choice})
        return true
      end
    elseif choice == "goude3" then
      local use = room:askToUseVirtualCard(player, {
        name = "slash",
        skill_name = goude.name,
        prompt = "#goude-slash",
        cancelable = true,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
        skip = true,
      })
      if use then
        event:setCostData(self, {choice = choice, extra_data = use})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "draw1" then
      player:drawCards(1, goude.name)
    elseif choice == "goude2" then
      local to = event:getCostData(self).tos[1]
      if to == player then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = goude.name,
          cancelable = false,
        })
      else
        local id = room:askToChooseCard(player, {
          target = to,
          flag = "h",
          skill_name = goude.name,
        })
        room:throwCard(id, goude.name, to, player)
      end
    elseif choice == "goude3" then
      room:useCard(event:getCostData(self).extra_data)
    elseif choice == "goude4" then
      local allKingdoms = {"wei", "shu", "wu", "qun", "jin"}
      local exceptedKingdoms = { player.kingdom }
      for _, kingdom in ipairs(exceptedKingdoms) do
        table.removeOne(allKingdoms, kingdom)
      end
      local kingdom = room:askToChoice(player, {
        choices = allKingdoms,
        skill_name = "AskForKingdom",
        prompt = "#ChooseInitialKingdom",
      })
      room:changeKingdom(player, kingdom, true)
    end
  end,
})

return goude
