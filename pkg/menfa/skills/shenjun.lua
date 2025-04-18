local shenjun = fk.CreateSkill{
  name = "shenjun",
}

Fk:loadTranslationTable{
  ["shenjun"] = "神君",
  [":shenjun"] = "当一名角色使用【杀】或普通锦囊牌时，你展示所有同名手牌记为“神君”，本阶段结束时，你可以将X张牌当任意“神君”牌使用（X为“神君”牌数）。",

  ["@$shenjun-phase"] = "神君",
  ["@@shenjun-inhand-phase"] = "神君",
  ["#shenjun-invoke"] = "神君：你可以将%arg张牌当一种“神君”牌使用",

  ["$shenjun1"] = "区区障眼之法，难遮神人之目。",
  ["$shenjun2"] = "我以天地为师，自可道法自然。",
}

shenjun:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shenjun.name) and not player:isKongcheng() and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).trueName == data.card.trueName
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == data.card.trueName
    end)
    player:showCards(cards)
    if player.dead then return end
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards == 0 then return end
    for _, id in ipairs(cards) do
      room:addTableMarkIfNeed(player, "@$shenjun-phase", id)
      room:setCardMark(Fk:getCardById(id), "@@shenjun-inhand-phase", 1)
    end
  end,
})

shenjun:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shenjun.name) and player:usedSkillTimes(shenjun.name, Player.HistoryPhase) > 0 and
      player:getMark("@$shenjun-phase") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card:getMark("@@shenjun-inhand-phase") > 0 then
        table.insertIfNeed(names, card.name)
      end
    end
    local use = room:askToUseVirtualCard(player, {
      name = names,
      skill_name = shenjun.name,
      prompt = "#shenjun-invoke:::"..#player:getMark("@$shenjun-phase"),
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      card_filter = {
        n = #player:getTableMark("@$shenjun-phase"),
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

shenjun:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@$shenjun") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@shenjun-inhand-phase") > 0
    end)
    player.room:setPlayerMark(player, "@$shenjun-phase", #cards > 0 and cards or 0)
  end,
})

return shenjun
