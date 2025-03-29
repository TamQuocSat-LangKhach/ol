local wanyi = fk.CreateSkill{
  name = "wanyi",
}

Fk:loadTranslationTable{
  ["wanyi"] = "婉嫕",
  [":wanyi"] = "当你使用【杀】或普通锦囊牌指定唯一其他角色为目标后，你可以将其一张牌置于你的武将牌上。"..
  "你不能使用、打出、弃置与“婉嫕”牌花色相同的牌。结束阶段或当你受到伤害后，你令一名角色获得一张“婉嫕”牌。",

  ["#wanyi-invoke"] = "婉嫕：你可以将 %dest 的一张牌置于你的武将牌上",
  ["#wanyi-give"] = "婉嫕：令一名角色获得一张“婉嫕”牌",

  ["$wanyi1"] = "天性婉嫕，易以道御。",
  ["$wanyi2"] = "婉嫕利珍，为后攸行。",
}

wanyi:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  derived_piles = "wanyi",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wanyi.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      data:isOnlyTarget(data.to) and data.to ~= player and not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = wanyi.name,
      prompt = "#wanyi-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = "he",
      skill_name = wanyi.name,
    })
    player:addToPile(wanyi.name, card, true, wanyi.name)
  end,
})
wanyi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and table.find(player:getPile("wanyi"), function(id)
      return Fk:getCardById(id):compareSuitWith(card)
    end)
  end,
  prohibit_response = function(self, player, card)
    return card and table.find(player:getPile("wanyi"), function(id)
      return Fk:getCardById(id):compareSuitWith(card)
    end)
  end,
  prohibit_discard = function(self, player, card)
    return card and table.find(player:getPile("wanyi"), function(id)
      return Fk:getCardById(id):compareSuitWith(card)
    end)
  end,
})

local wanyi_spec = {
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:askToYiji(player, {
      cards = player:getPile(wanyi.name),
      targets = room.alive_players,
      skill_name = wanyi.name,
      min_num = 1,
      max_num = 1,
      prompt = "#wanyi-give",
      cancelable = false,
      expand_pile = player:getPile(wanyi.name),
    })
  end,
}
wanyi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wanyi.name) and player.phase == Player.Finish and
      #player:getPile(wanyi.name) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = wanyi_spec.on_use,
})
wanyi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wanyi.name) and
      #player:getPile(wanyi.name) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = wanyi_spec.on_use,
})


return wanyi
