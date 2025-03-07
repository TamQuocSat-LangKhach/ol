local xiangxu = fk.CreateSkill{
  name = "xiangxu",
}

Fk:loadTranslationTable{
  ["xiangxu"] = "相胥",
  [":xiangxu"] = "当你的手牌数变为全场最小后，本回合结束时，你可以将手牌调整至与当前回合角色相同（至多摸至五张），"..
  "若你以此法弃置了至少两张牌，你回复1点体力。",

  ["@@xiangxu-turn"] = "相胥",
  ["#xiangxu-discard"] = "相胥：你可以弃置%arg张手牌",
  ["#xiangxu_recover"] = "相胥：你可以弃置%arg张手牌并回复1点体力",
  ["#xiangxu-draw"] = "相胥：你可以摸%arg张牌",

  ["$xiangxu1"] = "今之大魏，非一家一姓之国。",
  ["$xiangxu2"] = "宇内同庆，奏凯歌于长垣。",
}

xiangxu:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiangxu.name) and player:getMark("@@xiangxu-turn") > 0 and not target.dead and
      (player:getHandcardNum() > target:getHandcardNum() or player:getHandcardNum() < math.min(target:getHandcardNum(), 5))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x, y = player:getHandcardNum(), target:getHandcardNum()
    if x > y then
      local n = x - y
      local prompt = "#xiangxu-discard:::"..n
      if n > 1 then
        prompt = "#xiangxu-recover:::"..n
      end
      local cards = room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = xiangxu.name,
        prompt = prompt,
        cancelable = true,
        skip = true,
      })
      if #cards > 0 then
        event:setCostData(self, {tos = {target}, cards = cards})
        return true
      end
    else
      local n = math.min(y, 5) - x
      if room:askToSkillInvoke(player, {
        skill_name = xiangxu.name,
        prompt = "#xiangxu-draw:::"..n,
      }) then
        event:setCostData(self, {tos = {target}, cards = {}})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(player, "xiangxu_targets", target.id)
    local cards = event:getCostData(self).cards
    if #cards > 0 then
      room:throwCard(cards, xiangxu.name, player, player)
      if #cards > 1 and player:isWounded() and not player.dead then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = xiangxu.name,
        }
      end
    else
      local n = math.min(target:getHandcardNum(), 5) - player:getHandcardNum()
      player:drawCards(n, xiangxu.name)
    end
  end,
})

xiangxu:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    if player:hasSkill(xiangxu.name, true) and player:getMark("@@xiangxu-turn") == 0 and
      player.room.current ~= player and
      table.every(player.room.alive_players, function (p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
        if move.to == player and move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@xiangxu-turn", 1)
  end,
})

return xiangxu
