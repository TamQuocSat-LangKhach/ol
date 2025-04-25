local fangzhen = fk.CreateSkill{
  name = "fangzhen",
}

Fk:loadTranslationTable{
  ["fangzhen"] = "放赈",
  [":fangzhen"] = "出牌阶段开始时，你可以横置一名角色，然后选择：1.摸两张牌并交给其两张牌；2.令其回复1点体力。第X轮开始时（X为其座次），"..
  "你失去此技能。",

  ["#fangzhen-choose"] = "放赈：你可以横置一名角色，摸两张牌交给其或令其回复体力",
  ["fangzhen_draw"] = "摸两张牌并交给其两张牌",
  ["fangzhen_recover"] = "令其回复1点体力",
  ["#fangzhen-choice"] = "放赈：选择对 %dest 执行的一项",
  ["#fangzhen-give"] = "放赈：选择两张牌交给 %dest",

  ["$fangzhen1"] = "百姓罹灾，当施粮以赈。",
  ["$fangzhen2"] = "开仓放粮，以赈灾民。",
}

fangzhen:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fangzhen.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p)
        return not p.chained
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p.chained
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = fangzhen.name,
      prompt = "#fangzhen-choose",
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
    if to.seat > room:getBanner("RoundCount") and player:getMark(fangzhen.name) < to.seat then
      room:setPlayerMark(player, fangzhen.name, to.seat)
    end
    to:setChainState(true)
    if to.dead or player.dead then return end
    local choices = {"fangzhen_draw"}
    if to:isWounded() then
      table.insert(choices, "fangzhen_recover")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = fangzhen.name,
      prompt = "#fangzhen-choice::"..to.id,
    })
    if choice == "fangzhen_draw" then
      player:drawCards(2, fangzhen.name)
      if to == player or player.dead or to.dead then return end
      local cards = player:getCardIds("he")
      if #cards > 2 then
        cards = room:askToCards(player, {
          min_num = 2,
          max_num = 2,
          include_equip = true,
          skill_name = fangzhen.name,
          prompt = "#fangzhen-give::"..to.id,
          cancelable = false,
        })
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, to, fk.ReasonGive, fangzhen.name, nil, false, player)
      end
    else
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = fangzhen.name,
      }
    end
  end,
})
fangzhen:addEffect(fk.RoundStart, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fangzhen.name, true) and player:getMark(fangzhen.name) == player.room:getBanner("RoundCount")
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-fangzhen")
  end,
})

fangzhen:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, fangzhen.name, 0)
end)

return fangzhen
