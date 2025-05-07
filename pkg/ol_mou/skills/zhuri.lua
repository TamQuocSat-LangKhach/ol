local zhuri = fk.CreateSkill{
  name = "zhuri",
}

Fk:loadTranslationTable{
  ["zhuri"] = "逐日",
  [":zhuri"] = "你的阶段结束时，若你本阶段手牌数变化过，你可以拼点：若你赢，你可以使用一张拼点牌；若你没赢，你失去1点体力或本技能直到回合结束。",

  ["#zhuri-choose"] = "逐日：你可以拼点，若赢，你可以使用一张拼点牌；若没赢，你失去1点体力或本回合失去〖逐日〗",
  ["#zhuri-use"] = "逐日：你可以使用其中一张牌",
  ["lose_zhuri"] = "失去〖逐日〗直到回合结束",

  ["$zhuri1"] = "效逐日之夸父，怀忠志而长存。",
  ["$zhuri2"] = "知天命而不顺，履穷途而强为。",
}

zhuri:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhuri.name) and
      player.phase >= Player.Start and player.phase <= Player.Finish and not player:isKongcheng() then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player and move.toArea == Card.PlayerHand then
            return true
          end
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                return true
              end
            end
          end
        end
      end, Player.HistoryPhase) > 0 and
      table.find(player.room.alive_players, function(p)
        return player:canPindian(p)
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhuri.name,
      prompt = "#zhuri-choose",
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
    local pindian = player:pindian({to}, zhuri.name)
    if player.dead then return end
    if pindian.results[to].winner == player then
      local ids = {}
      for _, card in ipairs({pindian.fromCard, pindian.results[to].toCard}) do
        if room:getCardArea(card) == Card.DiscardPile then
          table.insertIfNeed(ids, card:getEffectiveId())
        end
      end
      ids = table.filter(ids, function (id)
        local card = Fk:getCardById(id)
        return not player:prohibitUse(card) and player:canUse(card, { bypass_times = true })
      end)
      if #ids == 0 then return false end
      room:askToUseRealCard(player, {
        pattern = ids,
        skill_name = zhuri.name,
        prompt = "#zhuri-use",
        extra_data = {
          bypass_times = true,
          extraUse = true,
          expand_pile = ids,
        }
      })
    else
      local choice = room:askToChoice(player, {
        choices = {"loseHp", "lose_zhuri"},
        skill_name = zhuri.name,
      })
      if choice == "loseHp" then
        room:loseHp(player, 1, zhuri.name)
      else
        local turn = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
        if turn ~= nil and player:hasSkill(zhuri.name, true) then
          room:handleAddLoseSkills(player, "-zhuri")
          turn:addCleaner(function()
            room:handleAddLoseSkills(player, "zhuri")
          end)
        end
      end
    end
  end,
})

return zhuri
