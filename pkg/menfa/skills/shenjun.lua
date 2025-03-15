local shenjun = fk.CreateSkill{
  name = "shenjun",
}

Fk:loadTranslationTable{
  ["shenjun"] = "神君",
  [":shenjun"] = "当一名角色使用【杀】或普通锦囊牌时，你展示所有同名手牌记为“神君”，本阶段结束时，你可以将X张牌当任意“神君”牌使用（X为“神君”牌数）。",

  ["@$shenjun-phase"] = "神君",
  ["@@shenjun-inhand-phase"] = "神君",
  ["#shenjun-invoke"] = "神君：你可以将%arg张牌当一种“神君”牌使用",
  ["shenjun_viewas"] = "神君",

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
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "shenjun_viewas",
      prompt = "#shenjun-invoke:::"..#player:getMark("@$shenjun-phase"),
      cancelable = true,
      extra_data = {
        bypass_times = true,
      }
    })
    if success and dat then
      event:setCostData(self, {extra_data = dat})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = table.simpleClone(event:getCostData(self).extra_data)
    local card = Fk:cloneCard(dat.interaction)
    card:addSubcards(dat.cards)
    card.skillName = shenjun.name
    room:useCard{
      from = player,
      tos = dat.targets,
      card = card,
      extraUse = true,
    }
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
