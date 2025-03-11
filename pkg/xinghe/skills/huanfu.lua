local huanfu = fk.CreateSkill{
  name = "huanfu",
}

Fk:loadTranslationTable{
  ["huanfu"] = "宦浮",
  [":huanfu"] = "当你使用【杀】指定目标后或成为【杀】的目标后，你可以弃置任意张牌（至多为你的体力上限），此【杀】结算后，"..
  "若对目标角色造成的伤害值为弃牌数，你摸弃牌数两倍的牌。",

  ["#huanfu-invoke"] = "宦浮：弃置至多%arg张牌，若此【杀】造成伤害值等于弃牌数，你摸两倍的牌",

  ["$huanfu1"] = "宦海浮沉，莫问前路。",
  ["$huanfu2"] = "仕途险恶，吉凶难料。",
}

local huanfu_spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = player.maxHp,
      include_equip = true,
      skill_name = huanfu.name,
      prompt = "#huanfu-invoke:::"..player.maxHp,
      cancelable = true,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cards = event:getCostData(self).cards
    data.extra_data = data.extra_data or {}
    data.extra_data.huanfu = data.extra_data.huanfu or {}
    data.extra_data.huanfu[player] = #cards
    player.room:throwCard(cards, huanfu.name, player, player)
  end,
}

huanfu:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huanfu.name) and data.card.trueName == "slash" and
      not player:isNude() and data.firstTarget
  end,
  on_cost = huanfu_spec.on_cost,
  on_use = huanfu_spec.on_use,
})
huanfu:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huanfu.name) and data.card.trueName == "slash" and
      not player:isNude()
  end,
  on_cost = huanfu_spec.on_cost,
  on_use = huanfu_spec.on_use,
})

huanfu:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.damageDealt and data.extra_data and
      data.extra_data.huanfu and data.extra_data.huanfu[player] then
      local n = 0
      for _, p in ipairs(data.tos) do
        if data.damageDealt[p] then
          n = n + data.damageDealt[p]
        end
      end
      if data.extra_data.huanfu[player] == n then
        event:setCostData(self, {choice = 2 * data.extra_data.huanfu[player]})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self).choice, huanfu.name)
  end,
})

return huanfu
