local yichi = fk.CreateSkill{
  name = "yichi",
}

Fk:loadTranslationTable{
  ["yichi"] = "义叱",
  [":yichi"] = "结束阶段，你可以拼点，若你赢，其依次执行〖间难〗前X个选项（X为你本回合发动〖间难〗的次数）。",

  ["#yichi-choose"] = "义叱：你可以与一名角色拼点，若赢，其执行“间难”前%arg项",

  ["$yichi1"] = "",
  ["$yichi2"] = "",
}

yichi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yichi.name) and player.phase == Player.Finish and
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
      skill_name = yichi.name,
      prompt = "#yichi-choose:::"..player:usedSkillTimes("jiannan", Player.HistoryTurn),
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
    local pindian = player:pindian({to}, yichi.name)
    if pindian.results[to].winner == player then
      if to.dead then return end
      local n = player:usedSkillTimes("jiannan", Player.HistoryTurn)
      if n > 0 then
        room:askToDiscard(to, {
          min_num = 2,
          max_num = 2,
          include_equip = true,
          skill_name = yichi.name,
          cancelable = false,
        })
        if to.dead then return end
        if n > 1 then
          to:drawCards(2, yichi.name)
          if to.dead then return end
          if n > 2 then
            if #to:getCardIds("e") > 0 then
              room:recastCard(to:getCardIds("e"), to, yichi.name)
              if to.dead then return end
            end
            if n > 3 then
              local card = room:askToCards(to, {
                min_num = 1,
                max_num = 1,
                include_equip = false,
                skill_name = yichi.name,
                pattern = ".|.|.|.|.|trick",
                prompt = "#jiannan-put",
                cancelable = true,
              })
              if #card > 0 then
                room:moveCards({
                  ids = card,
                  from = to,
                  toArea = Card.DrawPile,
                  moveReason = fk.ReasonPut,
                  skillName = yichi.name,
                  moveVisible = true,
                  drawPilePosition = 1,
                })
              else
                room:loseHp(to, 1, yichi.name)
              end
            end
          end
        end
      end
    end
  end,
})

return yichi
