local liuju = fk.CreateSkill{
  name = "liuju",
}

Fk:loadTranslationTable{
  ["liuju"] = "留驹",
  [":liuju"] = "出牌阶段结束时，你可以与一名角色拼点，输的角色可以使用拼点牌中的任意张非基本牌。若你与其相互距离因此变化，你复原〖恤民〗。",

  ["#liuju-choose"] = "留驹：你可以拼点，输的角色可以使用其中的非基本牌",
  ["#liuju-use"] = "留驹：你可以使用其中的非基本牌",

  ["$liuju1"] = "当逐千里之驹，情深可留嬴城。",
  ["$liuju2"] = "乡老十里相送，此驹可彰吾情。",
}

liuju:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liuju.name) and player.phase == Player.Play and
      not player:isKongcheng() and
      table.find(player.room.alive_players, function(p)
        return player:canPindian(p)
      end)
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
      skill_name = liuju.name,
      prompt = "#liuju-choose",
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
    local pindian = player:pindian({to}, liuju.name)
    local loser = nil
    if pindian.results[to].winner == player then
      loser = to
    elseif pindian.results[to].winner == to then
      loser = player
    end
    if not loser or loser.dead then return false end
    local n1, n2 = player:distanceTo(to), to:distanceTo(player)
    local ids = {}
    table.insert(ids, pindian.fromCard:getEffectiveId())
    table.insert(ids, pindian.results[to].toCard:getEffectiveId())
    while not loser.dead do
      ids = table.filter(ids, function(id)
        local card = Fk:getCardById(id)
        return card.type ~= Card.TypeBasic and table.contains(room.discard_pile, id) and
          loser:canUse(card, { bypass_times = true })
      end)
      if #ids == 0 then break end
      local use = room:askToUseRealCard(loser, {
        pattern = ids,
        skill_name = liuju.name,
        prompt = "#liuju-use",
        extra_data = {
          bypass_times = true,
          extraUse = true,
          expand_pile = ids,
        },
        skip = true,
      })
      if use then
        table.removeOne(ids, use.card:getEffectiveId())
        room:useCard(use)
      else
        break
      end
    end
    if player:usedSkillTimes("xumin", Player.HistoryGame) > 0 and not player.dead and not to.dead and
      (player:distanceTo(to) ~= n1 or to:distanceTo(player) ~= n2) then
      player:setSkillUseHistory("xumin", 0, Player.HistoryGame)
    end
  end,
})

return liuju
