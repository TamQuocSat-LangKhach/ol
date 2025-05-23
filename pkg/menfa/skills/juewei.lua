local juewei = fk.CreateSkill{
  name = "juewei",
}

Fk:loadTranslationTable{
  ["juewei"] = "绝围",
  [":juewei"] = "每回合限一次，当你使用伤害牌指定目标后或成为伤害牌的目标后，你可以选择一项：1.重铸一张装备牌，此牌结算完成后，"..
  "你视为对除你以外一名目标角色使用此牌；2.弃置一张装备牌，令此牌无效。",

  ["#juewei-choice"] = "绝围：重铸一张装备，此牌结算后可以使用之；或弃置一张装备令此牌无效",
  ["#juewei-use"] = "绝围：你可以视为对其中一名角色使用【%arg】",

  ["$juewei1"] = "",
  ["$juewei2"] = "",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "juewei_active",
      prompt = "#juewei-choice",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    local choice = event:getCostData(self).choice
    if choice == "juewei_recast" then
      room:recastCard(cards, player, juewei.name)
      data.extra_data = data.extra_data or {}
      data.extra_data.juewei = data.extra_data.juewei or {}
      table.insertIfNeed(data.extra_data.juewei, player)
    else
      room:throwCard(cards, juewei.name, player, player)
      data.use.nullifiedTargets = table.simpleClone(room.players)
    end
  end,
}

juewei:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juewei.name) and data.firstTarget and
      data.card.is_damage_card and not player:isNude() and
      player:usedSkillTimes(juewei.name, Player.HistoryTurn) == 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})
juewei:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juewei.name) and
      data.card.is_damage_card and not player:isNude() and
      player:usedSkillTimes(juewei.name, Player.HistoryTurn) == 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

juewei:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.extra_data and data.extra_data.juewei and table.contains(data.extra_data.juewei, player) then
      local targets = table.filter(data.tos, function (p)
        return p ~= player and not p.dead and
          player:canUseTo(Fk:cloneCard(data.card.name), p, { bypass_distances = true, bypass_times = true })
      end)
      if #targets > 0 then
        event:setCostData(self, {extra_data = targets})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = data.card.name,
      skill_name = juewei.name,
      prompt = "#juewei-use:::"..data.card.name,
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        exclusive_targets = table.map(event:getCostData(self).extra_data, Util.IdMapper)
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

return juewei
