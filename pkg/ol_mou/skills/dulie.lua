local dulie = fk.CreateSkill{
  name = "ol__dulie",
}

Fk:loadTranslationTable{
  ["ol__dulie"] = "笃烈",
  [":ol__dulie"] = "每回合限一次，当你成为其他角色使用基本牌或普通锦囊牌的唯一目标时，"..
  "你可以令此牌的效果结算两次，然后此牌结算结束后，你摸X张牌（X为你的攻击范围且至多为5）。",

  ["#ol__dulie-invoke"] = "笃烈：是否令 %src 对你使用的%arg结算两次，结算后你摸攻击范围数量的牌？",

  ["$ol__dulie1"] = "秉同难共患之义，莫敢辞也。",
  ["$ol__dulie2"] = "慈赴府君之急，死又何惧尔？",
}

dulie:addEffect(fk.TargetConfirming, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dulie.name) and player:usedSkillTimes(dulie.name, Player.HistoryTurn) == 0 and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      data.from ~= player and #data.use.tos == 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = "#ol__dulie-invoke:"..data.from.."::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    data.use.additionalEffect = 1
    data.extra_data = data.extra_data or {}
    data.extra_data.ol__dulie = data.extra_data.ol__dulie or {}
    table.insert(data.extra_data.ol__dulie, player)
  end,
})
dulie:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:getAttackRange() > 0 and
      data.extra_data and data.extra_data.ol__dulie and table.contains(data.extra_data.ol__dulie, player)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.min(5, player:getAttackRange()), dulie.name)
  end,
})

return dulie
