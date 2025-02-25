local this = fk.CreateSkill{
  name = "ol_ex__lianhuan",
}

this:addEffect('active', {
  mute = true,
  card_num = 1,
  min_target_num = 0,
  prompt = "#ol_ex__lianhuan-active",
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Club
  end,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    if #selected_cards == 1 then
      local card = Fk:cloneCard("iron_chain")
      card:addSubcard(selected_cards[1])
      card.skillName = this.name
      return player:canUse(card) and card.skill:targetFilter(player, to_select, selected, selected_cards, card, nil) and
      not player:prohibitUse(card) and not player:isProhibited(to_select, card)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    player:broadcastSkillInvoke(this.name)
    if #effect.tos == 0 then
      room:notifySkillInvoked(player, this.name, "drawcard")
      room:recastCard(effect.cards, player, this.name)
    else
      room:notifySkillInvoked(player, this.name, "control")
      room:sortByAction(effect.tos)
      room:useVirtualCard("iron_chain", effect.cards, player, table.map(effect.tos, Util.Id2PlayerMapper), this.name)
    end
  end,
})

this:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and data.card.trueName == "iron_chain" and #player.room:getUseExtraTargets(data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, { targets = player.room:getUseExtraTargets(data), min_num = 1, max_num = 1,
      prompt = "#ol_ex__lianhuan-choose:::"..data.card:toLogString(), skill_name = this.name, cancelable = true
    })
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(this.name)
    data:addTarget(data.tos, self.cost_data)
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__lianhuan"] = "连环",
  [":ol_ex__lianhuan"] = "①出牌阶段，你可选择：1.将一张♣牌转化为【铁索连环】使用；2.重铸一张♣牌。"..
  "②当【铁索连环】选择目标后，若使用者为你，你可令一名角色也成为此牌的目标。",
  
  ["#ol_ex__lianhuan-active"] = "你是否想要发动“连环”将一张♣牌当【铁索连环】使用，或不选目标直接“确定”重铸",
  ["#ol_ex__lianhuan_trigger"] = "连环",
  ["#ol_ex__lianhuan-choose"] = "你可以发动 连环，为使用的【%arg】额外指定一个目标",
  
  ["$ol_ex__lianhuan1"] = "连环之策，攻敌之计。",
  ["$ol_ex__lianhuan2"] = "锁链连舟，困步难行。",
}

return this