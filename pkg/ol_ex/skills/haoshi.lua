local haoshi = fk.CreateSkill{
  name = "ol_ex__haoshi",
}

Fk:loadTranslationTable {
  ["ol_ex__haoshi"] = "好施",
  [":ol_ex__haoshi"] = "摸牌阶段，你可以额外摸两张牌，此阶段结束时，若你的手牌数大于5，你将一半的手牌交给除你外手牌数最少的一名角色。"..
  "当你于你的下个回合开始之前成为【杀】或普通锦囊牌的目标后，其可以将一张手牌交给你。",

  ["#ol_ex__haoshi-give"] = "好施：选择%arg张手牌，交给除你外手牌数最少的一名角色",
  ["#ol_ex__haoshi-regive"] = "好施：你可以将一张手牌交给 %src",

  ["$ol_ex__haoshi1"] = "仗义疏财，深得人心。",
  ["$ol_ex__haoshi2"] = "招聚少年，给其衣食。",
}

haoshi:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
})

haoshi:addEffect(fk.AfterDrawNCards, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:usedEffectTimes(haoshi.name, Player.HistoryPhase) > 0 and
      player:getHandcardNum() > 5 and not player.dead and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getHandcardNum() // 2
    local targets = {}
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if p ~= player then
        if #targets == 0 then
          table.insert(targets, p)
          n = p:getHandcardNum()
        else
          if p:getHandcardNum() < n then
            targets = {p}
            n = p:getHandcardNum()
          elseif p:getHandcardNum() == n then
            table.insert(targets, p)
          end
        end
      end
    end
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = x,
      max_card_num = x,
      targets = targets,
      min_num = 1,
      max_num = 1,
      pattern = ".|.|.|hand",
      prompt = "#ol_ex__haoshi-give:::" .. x,
      skill_name = "ol_ex__haoshi",
      cancelable = false,
    })
    local to = tos[1]
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, "ol_ex__haoshi", nil, false, player)
    if player.dead or to.dead then return false end
    room:addTableMarkIfNeed(player, "ol_ex__haoshi_target", to)
  end,
})

haoshi:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger =function (self, event, target, player, data)
    return target == player and player:getMark("ol_ex__haoshi_target") ~= 0 and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player:getTableMark("ol_ex__haoshi_target"), function (p)
        return not p.dead and not p:isKongcheng()
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player:getTableMark("ol_ex__haoshi_target"), function (p)
      return not p.dead and not p:isKongcheng()
    end)
    for _, p in ipairs(targets) do
      if player.dead then return end
      if not p.dead and not p:isKongcheng() then
        local card = room:askToCards(p, {
          min_num = 1,
          max_num = 1,
          skill_name = haoshi.name,
          cancelable = true,
          pattern = ".|.|.|hand",
          prompt = "#ol_ex__haoshi-regive:"..player.id,
        })
        if #card > 0 then
          room:obtainCard(player, card[1], false, fk.ReasonGive, p, haoshi.name)
        end
      end
    end
  end,
})

haoshi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "ol_ex__haoshi_target", 0)
  end,
})

return haoshi