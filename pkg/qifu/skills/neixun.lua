local neixun = fk.CreateSkill{
  name = "neixun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["neixun"] = "内训",
  [":neixun"] = "锁定技，其他角色于其回合内使用第一张非装备牌后，若此牌与你上次发动〖椒遇〗时声明的颜色相同/不同，"..
  "你交给/获得其一张牌，你/其摸一张牌。你以此法得到的牌不计入手牌上限直到你回合结束。",

  ["#neixun-give"] = "内训：你需交给 %dest 一张牌",
  ["#neixun-prey"] = "内训：获得 %dest 一张牌",
  ["@@neixun-inhand"] = "内训",

  ["$neixun1"] = "妾充女君之位，当处中馈之任。",
  ["$neixun2"] = "诸宫人非圣贤，偶有失，亦可谅。",
}

neixun:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(neixun.name) and player:getMark("@jiaoyu-round") ~= 0 and target ~= player and not target.dead and
      player.room.current == target and data.card.type ~= Card.TypeEquip then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == target and use.card.type ~= Card.TypeEquip
      end, Player.HistoryTurn)
      if #events == 1 and events[1] == player.room.logic:getCurrentEvent() then
        event:setCostData(self, {tos = {target}})
        if data.card:getColorString() == player:getMark("@jiaoyu-round") then
          return not player:isNude()
        else
          return not target:isNude()
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card:getColorString() == player:getMark("@jiaoyu-round") then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = neixun.name,
        prompt = "#neixun-give::"..target.id,
        cancelable = false,
      })
      room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonGive, neixun.name, nil, false, player)
      if not player.dead then
        player:drawCards(1, neixun.name, "top", "@@neixun-inhand")
      end
    else
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "he",
        skill_name = neixun.name,
        prompt = "#neixun-prey::"..target.id,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, neixun.name, nil, false, player, "@@neixun-inhand")
      if not target.dead then
        target:drawCards(1, neixun.name)
      end
    end
  end,
})
neixun:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and not player:isKongcheng()
  end,
  on_refresh = function (self, event, target, player, data)
    for _, id in ipairs(player:getCardIds("h")) do
      player.room:setCardMark(Fk:getCardById(id), "@@neixun-inhand", 0)
    end
  end,
})
neixun:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@neixun-inhand") > 0
  end,
})

return neixun
