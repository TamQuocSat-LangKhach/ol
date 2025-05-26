local wangxi = fk.CreateSkill {
  name = "ol_ex__wangxi",
}

Fk:loadTranslationTable{
  ["ol_ex__wangxi"] = "忘隙",
  [":ol_ex__wangxi"] = "当你对其他角色造成1点伤害后，或当你受到其他角色造成的1点伤害后，你可以摸两张牌，然后将其中一张牌交给该角色。",

  ["#ol_ex__wangxi-invoke"] = "忘隙：是否对 %dest 发动“忘隙”，摸两张牌并将其中一张牌交给其",
  ["#ol_ex__wangxi-give"] = "忘隙：将其中一张牌交给 %dest",

  ["$ol_ex__wangxi1"] = "以德报怨，怨消恨解。",
  ["$ol_ex__wangxi2"] = "冤冤相报，何时能了。",
}

wangxi:addEffect(fk.Damage, {
  anim_type = "drawcard",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wangxi.name) and
      data.to ~= player and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = wangxi.name,
      prompt = "#ol_ex__wangxi-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(2, wangxi.name)
    cards = table.filter(cards, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if player.dead or player:isNude() or data.to.dead or #cards == 0 then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = wangxi.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#ol_ex__wangxi-give::"..data.to.id,
    })
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, data.to, fk.ReasonGive, wangxi.name, nil, false, player)
    end
  end,
})

wangxi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wangxi.name) and
      data.from and data.from ~= player and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = wangxi.name,
      prompt = "#ol_ex__wangxi-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(2, wangxi.name)
    cards = table.filter(cards, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if player.dead or player:isNude() or data.from.dead or #cards == 0 then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = wangxi.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#ol_ex__wangxi-give::"..data.from.id,
    })
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, data.from, fk.ReasonGive, wangxi.name, nil, false, player)
    end
  end,
})

return wangxi
