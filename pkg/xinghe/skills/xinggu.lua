local xinggu = fk.CreateSkill{
  name = "xinggu",
}

Fk:loadTranslationTable{
  ["xinggu"] = "行贾",
  [":xinggu"] = "游戏开始时，你将随机三张坐骑牌置于你的武将牌上。结束阶段，你可以将其中一张牌置于一名其他角色的装备区，"..
  "然后你获得牌堆中一张<font color='red'>♦</font>牌。",

  ["#xinggu-invoke"] = "行贾：你可以将一张“行贾”坐骑置入一名角色装备区，然后获得一张<font color='red'>♦</font>牌",

  ["$xinggu1"] = "乱世烽烟，贾者如火中取栗尔。",
  ["$xinggu2"] = "天下动荡，货行千里可易千金。",
}

xinggu:addEffect(fk.GameStart, {
  derived_piles = "xinggu",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xinggu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id).sub_type == Card.SubtypeOffensiveRide or Fk:getCardById(id).sub_type == Card.SubtypeDefensiveRide then
        table.insertIfNeed(cards, id)
      end
    end
    player:addToPile(xinggu.name, table.random(cards, 3), true, xinggu.name)
  end,
})
xinggu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      #player:getPile(xinggu.name) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "xinggu_active",
      prompt = "#xinggu-invoke",
      no_indicate = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardIntoEquip(event:getCostData(self).tos[1], event:getCostData(self).cards, xinggu.name, true, player)
    if player.dead then return end
    local card = room:getCardsFromPileByRule(".|.|diamond")
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, xinggu.name, nil, false, player)
    end
  end,
})

return xinggu
