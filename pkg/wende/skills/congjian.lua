local congjian = fk.CreateSkill{
  name = "congjianx",
}

Fk:loadTranslationTable{
  ["congjianx"] = "从鉴",
  [":congjianx"] = "当体力值全场唯一最大的其他角色成为普通锦囊牌的唯一目标时，你可以也成为此牌目标，此牌结算后，若此牌对你造成伤害，你摸两张牌。",

  ["#congjianx-invoke"] = "从鉴：你可以成为此%arg的额外目标，若对你造成伤害，你摸两张牌",

  ["$congjianx1"] = "为人臣属，安可不随？",
  ["$congjianx2"] = "主公有难，吾当从之。",
}

congjian:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(congjian.name) and data.card:isCommonTrick() and
      #data.use.tos == 1 and
      table.every(player.room:getOtherPlayers(target, false), function (p)
        return target.hp > p.hp
      end) and
      data.from:canUseTo(data.card, player, {bypass_distances = true})
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = congjian.name,
      prompt = "#congjianx-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(player)
    data.extra_data = data.extra_data or {}
    data.extra_data.congjianx = data.extra_data.congjianx or {}
    table.insert(data.extra_data.congjianx, player)
  end,
})
congjian:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.damageDealt and data.damageDealt[player] and
      data.extra_data and data.extra_data.congjianx and table.contains(data.extra_data.congjianx, player)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, congjian.name)
  end,
})

return congjian
