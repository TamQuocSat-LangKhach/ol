local this = fk.CreateSkill{
  name = "ol_ex__huoji",
}

this:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "fire_attack",
  prompt = "#ol_ex__huoji-viewas",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = this.name
    card:addSubcard(cards[1])
    return card
  end,
})

this:addEffect(fk.PreCardEffect, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(this.name) and data.from == player.id and data.card.trueName == "fire_attack"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    card.skill = Fk.skills["ol_ex__huoji__fire_attack_skill"]
    data.card = card
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__huoji"] = "火计",
  [":ol_ex__huoji"] = "①你可以将一张红色牌转化为【火攻】使用。"..
  "②你使用的【火攻】的作用效果改为：目标角色随机展示一张手牌，然后你可以弃置一张与此牌颜色相同的手牌对其造成1点火焰伤害。",
  
  ["#ol_ex__huoji-viewas"] = "你是否想要发动“火计”，将一张红色牌当【火攻】使用",
  ["#ol_ex__huoji_buff"] = "火计",
  
  ["$ol_ex__huoji1"] = "赤壁借东风，燃火灭魏军。",
  ["$ol_ex__huoji2"] = "东风，让这火烧得再猛烈些吧！",
}

return this
