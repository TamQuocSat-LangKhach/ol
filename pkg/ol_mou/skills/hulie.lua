local hulie = fk.CreateSkill{
  name = "hulie",
}

Fk:loadTranslationTable{
  ["hulie"] = "虎烈",
  [":hulie"] = "每回合各限一次，当你使用【杀】或【决斗】指定唯一目标后，你可以令此牌伤害+1。此牌结算后，若未造成伤害，你可以令目标角色视为"..
  "对你使用一张【杀】。",

  ["#hulie-invoke"] = "虎烈：是否令此%arg伤害+1？",
  ["#hulie-slash"] = "虎烈：是否令 %dest 视为对你使用【杀】？",

  ["$hulie1"] = "匹夫犯我，吾必斩之。",
  ["$hulie2"] = "鼠辈，这一刀下去定让你看不到明天的太阳。",
}

hulie:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hulie.name) and
      (data.card.trueName == "slash" or data.card.trueName == "duel") and
      #data.use.tos == 1 and player:getMark("hulie_"..data.card.trueName.."-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = hulie.name,
      prompt = "#hulie-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "hulie_"..data.card.trueName.."-turn", 1)
    data.extra_data = data.extra_data or {}
    data.extra_data.hulie = player
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})
hulie:addEffect(fk.CardUseFinished, {
  anim_type = "masochism",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and
      not data.damageDealt and data.extra_data and data.extra_data.hulie == player and
      table.find(data.tos, function (p)
        return not p.dead and p ~= player and
          p:canUseTo(Fk:cloneCard("slash"), player, {bypass_distances = true, bypass_times = true})
      end)
  end,
  on_trigger = function (self, event, target, player, data)
    local targets = table.filter(data.tos, function (p)
      return not p.dead and p ~= player
    end)
    player.room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if player.dead then break end
      if not p.dead and p:canUseTo(Fk:cloneCard("slash"), player, {bypass_distances = true, bypass_times = true}) then
        event:setCostData(self, {extra_data = p})
        self:doCost(event, player, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = hulie.name,
      prompt = "#hulie-slash::"..event:getCostData(self).extra_data.id
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("slash", nil, event:getCostData(self).extra_data, player, hulie.name, true)
  end,
})

return hulie
