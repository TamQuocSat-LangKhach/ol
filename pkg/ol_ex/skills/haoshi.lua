local this = fk.CreateSkill{
  name = "ol_ex__haoshi",
}

this:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
})

this:addEffect(fk.AfterDrawNCards, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    return #player.player_cards[Player.Hand] > 5 and #player.room.alive_players > 1
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
          table.insert(targets, p.id)
          n = p:getHandcardNum()
        else
          if p:getHandcardNum() < n then
            targets = {p.id}
            n = p:getHandcardNum()
          elseif p:getHandcardNum() == n then
            table.insert(targets, p.id)
          end
        end
      end
    end
    local tos, cards = room:askToChooseCardsAndPlayers(player, { min_card_num = x, max_card_num = x, targets = targets, min_num = 1, max_num = 1,
      pattern = ".|.|.|hand", prompt = "#ol_ex__haoshi-give:::" .. x, skill_name = "ol_ex__haoshi", cancelable = false
    })
    local to = tos[1]
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, "ol_ex__haoshi", nil, false, player.id)
    if player.dead or to.dead then return false end
    local targetRecorded = player:getTableMark("ol_ex__haoshi_target")
    if table.insertIfNeed(targetRecorded, to.id) then
      room:setPlayerMark(player, "ol_ex__haoshi_target", targetRecorded)
    end
  end,
})

this:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger =function (self, event, target, player, data)
    if player.dead then return false end
    if player == target and type(player:getMark("ol_ex__haoshi_target")) == "table" then
      if data and (data.card.trueName == "slash" or data.card:isCommonTrick()) then
        local targetRecorded = player:getMark("ol_ex__haoshi_target")
        return table.find(targetRecorded, function (pid)
          local p = player.room:getPlayerById(pid)
          return p and p ~= player and not p:isKongcheng()
        end)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targetRecorded = player:getMark("ol_ex__haoshi_target")
    room:doIndicate(player.id, targetRecorded)
    room:sortByAction(targetRecorded)
    table.forEach(targetRecorded, function (pid)
      local p = room:getPlayerById(pid)
      if p and not player.dead and not p.dead and p ~= player and not p:isKongcheng() then
        local card = room:askToCards(p, { min_num = 1, max_num = 1, skill_name = this.name, cancelable = true, pattern = ".|.|.|hand", prompt = "#ol_ex__haoshi-regive:"..player.id})
        if #card > 0 then
          room:obtainCard(player, card[1], false, fk.ReasonGive, p.id)
        end
      end
    end)
  end,
})

this:addEffect(fk.TurnStart, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return player == target and type(player:getMark("ol_ex__haoshi_target")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "ol_ex__haoshi_target", 0)
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__haoshi"] = "好施",
  ["#ol_ex__haoshi_delay"] = "好施",
  [":ol_ex__haoshi"] = "摸牌阶段，你可令额定摸牌数+2，此阶段结束时，若你的手牌数大于5，你将一半的手牌交给除你外手牌数最少的一名角色。当你于你的下个回合开始之前成为【杀】或普通锦囊牌的目标后，你令其可将一张手牌交给你。",

  ["#ol_ex__haoshi-give"] = "好施：选择%arg张手牌，交给除你外手牌数最少的一名角色",
  ["#ol_ex__haoshi-regive"] = "好施：可以将一张手牌交给 %src",
  
  ["$ol_ex__haoshi1"] = "仗义疏财，深得人心。",
  ["$ol_ex__haoshi2"] = "招聚少年，给其衣食。",
}

return this