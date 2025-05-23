local tanfeng = fk.CreateSkill {
  name = "ol__tanfeng",
}

Fk:loadTranslationTable{
  ["ol__tanfeng"] = "探锋",
  [":ol__tanfeng"] = "出牌阶段限一次，你可以视为对一名角色使用一张不计次数、无视防具的【杀】。若此【杀】造成伤害，你摸X张牌"..
  "（X为其装备区与你装备区内牌数之差）；若未造成伤害，其可以视为对你使用一张【杀】。",

  ["#ol__tanfeng"] = "探锋：视为对一名角色使用无视防具的【杀】，若造成伤害则摸牌，否则其可以视为对你使用【杀】",
  ["#ol__tanfeng-slash"] = "探锋：是否视为对 %src 使用【杀】？",

  ["$ol__tanfeng1"] = "",
  ["$ol__tanfeng2"] = "",
}

tanfeng:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol__tanfeng",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(tanfeng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local card = Fk:cloneCard("slash")
    card.skillName = tanfeng.name
    return card.skill:modTargetFilter(player, to_select, selected, card, { bypass_times = true })
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = Fk:cloneCard("slash")
    card.skillName = tanfeng.name
    local use = {
      from = player,
      tos = {target},
      card = card,
      extraUse = true,
      extra_data = {
        ol__tanfeng = {
          from = player,
          to = target,
        },
      }
    }
    room:useCard(use)
  end,
})

tanfeng:addEffect(fk.TargetSpecified, {
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.ol__tanfeng and data.extra_data.ol__tanfeng.from == player and
      data.to == data.extra_data.ol__tanfeng.to and not data.to.dead
  end,
  on_refresh = function(self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})

tanfeng:addEffect(fk.CardUseFinished, {
  priority = 1.1,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.ol__tanfeng and
      data.extra_data.ol__tanfeng.from == player
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = data.extra_data.ol__tanfeng.to
    if data.damageDealt and data.damageDealt[to] then
      local n = math.abs(#player:getCardIds("e") - #to:getCardIds("e"))
      if n > 0 then
        player:drawCards(n, tanfeng.name)
      end
    elseif not to.dead and not to:isProhibited(player, Fk:cloneCard("slash")) and
      room:askToSkillInvoke(to, {
      skill_name = tanfeng.name,
      prompt = "#ol__tanfeng-slash:"..player.id,
    }) then
      room:useVirtualCard("slash", nil, to, player, tanfeng.name, true)
    end
  end,
})

return tanfeng
