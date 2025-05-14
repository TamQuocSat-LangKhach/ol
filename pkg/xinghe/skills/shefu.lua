local shefu = fk.CreateSkill{
  name = "shefu",
}

Fk:loadTranslationTable{
  ["shefu"] = "设伏",
  [":shefu"] = "结束阶段开始时，你可将一张手牌扣置于武将牌上，称为“伏兵”。若如此做，你为“伏兵”记录一个基本牌或锦囊牌的名称"..
  "（须与其他“伏兵”记录的名称均不同）。当其他角色于你的回合外使用手牌时，你可将记录的牌名与此牌相同的一张“伏兵”置入弃牌堆，然后此牌无效。",

  ["#shefu-ask"] = "设伏：你可以将一张手牌扣置为“伏兵”",
  ["$shefu"] = "伏兵",
  ["@shefu"] = "伏兵",
  ["#shefu-invoke"] = "设伏：是否令 %dest 使用的%arg无效？",

  ["$shefu1"] = "圈套已设，埋伏已完，只等敌军进来。",
  ["$shefu2"] = "如此天网，量你插翅也难逃。",
}

shefu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  derived_piles = "$shefu",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shefu.name) and player.phase == Player.Finish and
      not player:isKongcheng() and #player:getPile("$shefu") < #Fk:getAllCardNames("btd")
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "shefu_active",
      prompt = "#shefu-ask",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards, choice = dat.interaction})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self).cards
    local name = event:getCostData(self).choice
    room:moveCardTo(card, Card.PlayerSpecial, player, fk.ReasonJustMove, shefu.name, "$shefu", false, player,
      {"@shefu", Fk:translate(name)})
  end,
})
shefu:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shefu.name) and target ~= player and player.room.current ~= player and
      (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and
      data:isUsingHandcard(target) and
      table.find(player:getPile("$shefu"), function (id)
        return Fk:getCardById(id):getMark("@shefu") == Fk:translate(data.card.trueName)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shefu.name,
      prompt = "#shefu-invoke::"..target.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.toCard = nil
    data:removeAllTargets()
    local id = table.filter(player:getPile("$shefu"), function (id)
      return Fk:getCardById(id):getMark("@shefu") == Fk:translate(data.card.trueName)
    end)
    room:moveCardTo(id, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, shefu.name, nil, true, player)
  end,
})
shefu:addEffect(fk.AfterCardsMove, {
  can_refresh = Util.TrueFunc,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from then
        for _, info in ipairs(move.moveInfo) do
          if info.fromSpecialName == "$shefu" then
            player.room:setCardMark(Fk:getCardById(info.cardId), "@shefu", 0)
          end
        end
      end
    end
  end,
})

return shefu
