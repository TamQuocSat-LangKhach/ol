local hongtu = fk.CreateSkill{
  name = "hongtu",
}

Fk:loadTranslationTable{
  ["hongtu"] = "鸿图",
  [":hongtu"] = "一名角色的阶段结束时，若你于此阶段内得到过的牌数大于1，你可以摸三张牌，展示三张手牌并选择一名其他角色。"..
  "其可以使用其中一张牌，随机弃置另一张牌，若其以此法使用的牌：为这三张牌中唯一点数最大的牌，其获得〖飞军〗直到其下回合结束；"..
  "不为这三张牌中点数最大的牌且不为这三张牌中点数最小的牌，其获得〖潜袭〗直到其下回合结束；"..
  "为这三张牌中唯一点数最小的牌，其手牌上限+2直到其下回合结束。若其未以此法使用牌，你对其与你各造成1点火焰伤害。",

  ["#hongtu-give"] = "鸿图：选择三张手牌并选择一名其他角色，其可以使用其中一张",
  ["#hongtu-use"] = "鸿图：你可以使用其中一张牌",

  ["$hongtu1"] = "当下春风正好，君可扶摇而上。",
  ["$hongtu2"] = "得卧龙凤雏相助，主公大业可成。",
}

hongtu:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(hongtu.name) and target.phase >= Player.Start and target.phase <= Player.Finish then
      local x = 0
      local room = player.room
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.to == player and move.toArea == Card.PlayerHand then
            x = x + #move.moveInfo
            if x > 1 then return true end
          end
        end
      end, nil, Player.HistoryPhase)
      return x > 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, hongtu.name)
    if player.dead or player:getHandcardNum() < 3 or #room.alive_players < 2 then return false end
    local to, ids = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 3,
      max_card_num = 3,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|.|hand",
      skill_name = hongtu.name,
      prompt = "#hongtu-give",
      cancelable = false,
    })
    player:showCards(ids)
    ids = table.filter(ids, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    to = to[1]
    if #ids < 3 or to.dead then return end
    local use = room:askToUseRealCard(to, {
      pattern = ids,
      skill_name = hongtu.name,
      prompt = "#hongtu-use",
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = ids,
      },
      cancelable = true,
      skip = true,
    })
    if use then
      table.sort(ids, function (a, b)
        return Fk:getCardById(a).number > Fk:getCardById(b).number
      end)
      local hongtuBig = (Fk:getCardById(ids[1]).number ~= Fk:getCardById(ids[2]).number)
      local hongtuSmall = (Fk:getCardById(ids[2]).number ~= Fk:getCardById(ids[3]).number)
      room:useCard(use)
      if not player.dead then
        local handcards = player:getCardIds("h")
        local to_discard = table.filter(ids, function (id)
          return table.contains(handcards, id) and not player:prohibitDiscard(id)
        end)
        if #to_discard > 0 then
          room:throwCard(table.random(to_discard), hongtu.name, player)
        end
      end
      if to.dead then return false end
      if ids[1] == use.card.id and hongtuBig then
        if room.current == to then
          room:setPlayerMark(to, "hongtu1-turn", 1)
        end
        if not to:hasSkill("feijun", true) then
          room:setPlayerMark(to, "hongtu1", 1)
          room:handleAddLoseSkills(to, "feijun")
        end
      elseif ids[3] == use.card.id and hongtuSmall then
        room:setPlayerMark(to, "hongtu2", 1)
        if room.current == to then
          room:setPlayerMark(to, "hongtu2-turn", 1)
        end
      elseif ids[2] == use.card.id and hongtuBig and hongtuSmall then
        if room.current == to then
          room:setPlayerMark(to, "hongtu3-turn", 1)
        end
        if not to:hasSkill("re__qianxi", true) then
          room:setPlayerMark(to, "hongtu3", 1)
          room:handleAddLoseSkills(to, "re__qianxi")
        end
      end
    else
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = hongtu.name,
      }
      if not player.dead then
        room:damage{
          from = player,
          to = player,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = hongtu.name,
        }
      end
    end
  end,
})
hongtu:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return player == target and not target.dead
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = {}
    if player:getMark("hongtu1") > 0 and player:getMark("hongtu1-turn") == 0 then
      room:setPlayerMark(player, "hongtu1", 0)
      if player:hasSkill("feijun", true) then
        table.insert(skills, "-feijun")
      end
    end
    if player:getMark("hongtu2") > 0 and player:getMark("hongtu2-turn") == 0 then
      room:setPlayerMark(player, "hongtu2", 0)
    end
    if player:getMark("hongtu3") > 0 and player:getMark("hongtu3-turn") == 0 then
      room:setPlayerMark(player, "hongtu3", 0)
      if player:hasSkill("re__qianxi", true) then
        table.insert(skills, "-re__qianxi")
      end
    end
    if #skills > 0 then
      room:handleAddLoseSkills(player, table.concat(skills, "|"))
    end
  end,
})
hongtu:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:getMark("hongtu2") > 0 then
      return 2
    end
  end,
})

return hongtu
