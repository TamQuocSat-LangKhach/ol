local bianyu = fk.CreateSkill{
  name = "bianyu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["bianyu"] = "鞭御",
  [":bianyu"] = "锁定技，你使用【杀】造成伤害或受到【杀】的伤害后，你选择受伤角色至多X张手牌，这些牌视为无次数限制的【杀】，直到其使用非基本牌"..
  "（X为其已损失体力值）。若你或其手牌均为【杀】，你摸两张牌。",

  ["#bianyu-choose"] = "鞭御：选择 %dest 至多%arg张手牌，这些牌视为【杀】",
  ["@@bianyu-inhand"] = "鞭御",

  ["$bianyu1"] = "不挨几鞭子，你还出不了力了？",
  ["$bianyu2"] = "给我向前冲！把敌人杀光！",
}

local bianyu_spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bianyu.name) and data.card and data.card.trueName == "slash" and
      not data.to.dead and not data.to:isKongcheng() and data.to:isWounded()
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {data.to}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      target = data.to,
      min = 1,
      max = data.to:getLostHp(),
      flag = "h",
      skill_name = bianyu.name,
      prompt = "#bianyu-choose::"..data.to.id..":"..data.to:getLostHp(),
    })
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@bianyu-inhand", 1)
    end
    data.to:filterHandcards()
    cards = player:getCardIds("h")
    if #cards > 0 and table.every(cards, function (id)
      return Fk:getCardById(id).trueName == "slash"
    end) then
      player:drawCards(2, bianyu.name)
    elseif data.to ~= player then
      cards = data.to:getCardIds("h")
      if #cards > 0 and table.every(cards, function (id)
        return Fk:getCardById(id).trueName == "slash"
      end) then
        player:drawCards(2, bianyu.name)
      end
    end
  end,
}

bianyu:addEffect(fk.Damage, bianyu_spec)
bianyu:addEffect(fk.Damaged, bianyu_spec)

bianyu:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    if data.card:getMark("@@bianyu-inhand") > 0 then
      data.extraUse = true
    end
    if data.card.type ~= Card.TypeBasic then
      for _, id in ipairs(player:getCardIds("h")) do
        player.room:setCardMark(Fk:getCardById(id), "@@bianyu-inhand", 0)
      end
      player:filterHandcards()
    end
  end,
})

bianyu:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("@@bianyu-inhand") > 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

bianyu:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@bianyu-inhand") > 0
  end,
})

return bianyu
