local jiannan = fk.CreateSkill{
  name = "jiannan",
}

Fk:loadTranslationTable{
  ["jiannan"] = "间难",
  [":jiannan"] = "出牌阶段开始时，你可以摸两张牌。若如此做，此阶段当一名角色失去所有“间难”牌后或最后的手牌后，若没有角色处于濒死状态，"..
  "你令一名角色执行一项（每回合每项限一次）：1.弃置两张牌；2.摸两张牌；3.重铸装备区所有牌；4.其需将一张锦囊牌置于牌堆顶，否则失去1点体力。",

  ["@@jiannan-inhand-phase"] = "间难",
  ["#jiannan-choose"] = "间难：令一名角色执行一项",
  ["jiannan1"] = "弃置两张牌",
  ["jiannan2"] = "摸两张牌",
  ["jiannan3"] = "重铸装备区所有牌",
  ["jiannan4"] = "其需将一张锦囊牌置于牌堆顶，否则失去1点体力",
  ["#jiannan-put"] = "间难：请将一张锦囊牌置于牌堆顶，否则失去1点体力",
}

jiannan:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jiannan.name) and player.phase == Player.Play
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, jiannan.name, nil, "@@jiannan-inhand-phase")
  end,
})

jiannan:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if player:usedSkillTimes(jiannan.name, Player.HistoryPhase) > 0 and
      #player:getTableMark("jiannan-turn") < 4 and
      not table.find(player.room.alive_players, function (p)
        return p.dying
      end) then
      for _, move in ipairs(data) do
        if move.from and (move.from:isKongcheng() or
          (move.extra_data and move.extra_data.jiannan and
          not table.find(move.from:getCardIds("h"), function(id)
            return Fk:getCardById(id):getMark("@@jiannan-inhand-phase") > 0
          end))) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "jiannan_active",
      prompt = "#jiannan-choose",
      cancelable = false,
    })
    if not (success and dat) then
      dat = {}
      dat.targets = {player}
      dat.interaction = table.filter({1, 2, 3, 4}, function (i)
        return not table.contains(player:getTableMark("jiannan-turn"), i)
      end)
    end
    room:doIndicate(player, dat.targets)
    local to = dat.targets[1]
    local choice = tonumber(dat.interaction[8])
    room:addTableMark(player, "jiannan-turn", choice)
    if choice == 1 then
      room:askToDiscard(to, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = jiannan.name,
        cancelable = false,
      })
    elseif choice == 2 then
      to:drawCards(2, jiannan.name, nil, "@@jiannan-inhand-phase")
    elseif choice == 3 then
      if #to:getCardIds("e") > 0 then
        room:recastCard(to:getCardIds("e"), to, jiannan.name)
      end
    elseif choice == 4 then
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = jiannan.name,
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
          skillName = jiannan.name,
          moveVisible = true,
          drawPilePosition = 1,
        })
      else
        room:loseHp(to, 1, jiannan.name)
      end
    end
  end,
})

jiannan:addEffect(fk.BeforeCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(jiannan.name, true) and player:usedSkillTimes(jiannan.name, Player.HistoryPhase) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@jiannan-inhand-phase") > 0 then
            move.extra_data = move.extra_data or {}
            move.extra_data.jiannan = true
            break
          end
        end
      end
    end
  end,
})

return jiannan
