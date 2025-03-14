local qiajue = fk.CreateSkill{
  name = "qiajue",
}

Fk:loadTranslationTable{
  ["qiajue"] = "跒倔",
  [":qiajue"] = "摸牌阶段开始时，你可以弃置一张黑色牌并于本阶段结束时展示所有手牌，若点数和大于30，你的手牌上限-2，"..
  "否则你执行一个额外的摸牌阶段。",

  ["#qiajue-invoke"] = "跒倔：弃一张黑色牌，摸牌后手牌点数和≤30则获得额外摸牌阶段<font color='red'>（当前为%arg）</font>",

  ["$qiajue1"] = "汉旗未复，此生不居檐下。",
  ["$qiajue2"] = "蜀川大好，皆可为家。",
}

qiajue:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiajue.name) and player.phase == Player.Draw and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, id in ipairs(player:getCardIds("h")) do
      n = n + Fk:getCardById(id).number
    end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = qiajue.name,
      pattern = ".|.|spade,club",
      prompt = "#qiajue-invoke:::"..n,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, qiajue.name, player, player)
  end,
})
qiajue:addEffect(fk.EventPhaseEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes(qiajue.name, Player.HistoryPhase) > 0 and not (player.dead or player:isKongcheng())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("h")
    local n = 0
    for _, id in ipairs(cards) do
      n = n + Fk:getCardById(id).number
    end
    player:showCards(cards)
    if player.dead then return end
    if n > 30 then
      room:addPlayerMark(player, MarkEnum.MinusMaxCards, 2)
    else
      player:gainAnExtraPhase(Player.Draw, qiajue.name)
    end
  end,
})

return qiajue
