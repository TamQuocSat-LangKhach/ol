local pimi = fk.CreateSkill{
  name = "pimi",
}

Fk:loadTranslationTable{
  ["pimi"] = "披靡",
  [":pimi"] = "当你使用的牌指定其他角色为唯一目标后，或当你成为其他角色使用的牌的唯一目标后，你可以弃置使用者的一张牌，"..
  "令此牌的伤害值基数及回复值基数+1，此牌结算结束后，若使用者为手牌数最大或最小的角色，你摸一张牌，此技能本回合失效。",

  ["#pimi-invoke"] = "披靡：你可以弃置 %dest 一张牌，令其使用的%arg伤害值/回复值+1",

  ["$pimi1"] = "什么？赵云大怒，已经打过来啦？！",
  ["$pimi2"] = "我韩家五虎出手，必定所向披靡！",
}

pimi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(pimi.name) and
      #data.use.tos == 1 and data.to ~= player and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = pimi.name,
      prompt = "#pimi-invoke::"..player.id..":"..data.card:toLogString(),
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, pimi.name, player, player)
    data.additionalRecover = (data.additionalRecover or 0) + 1
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.extra_data = data.extra_data or {}
    data.extra_data.pimi = data.extra_data.pimi or {}
    table.insert(data.extra_data.pimi, player)
  end,
})
pimi:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(pimi.name) and
      #data.use.tos == 1 and data.from ~= player and not data.from:isNude() and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = pimi.name,
      prompt = "#pimi-invoke::"..data.from.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = data.from,
      flag = "he",
      skill_name = pimi.name,
    })
    room:throwCard(card, pimi.name, data.from, player)
    data.additionalRecover = (data.additionalRecover or 0) + 1
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.extra_data = data.extra_data or {}
    data.extra_data.pimi = data.extra_data.pimi or {}
    table.insert(data.extra_data.pimi, player)
  end,
})
pimi:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return data.extra_data and data.extra_data.pimi and table.contains(data.extra_data.pimi, player) and
      (table.every(player.room.alive_players, function (p)
        return p:getHandcardNum() <= data.from:getHandcardNum()
      end) or
      table.every(player.room.alive_players, function (p)
        return p:getHandcardNum() >= data.from:getHandcardNum()
      end))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, pimi.name)
    if player.dead then return end
    room:invalidateSkill(player, pimi.name, "-turn")
  end,
})

return pimi
