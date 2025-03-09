local huoji = fk.CreateSkill{
  name = "ol_ex__huoji",
}

Fk:loadTranslationTable {
  ["ol_ex__huoji"] = "火计",
  [":ol_ex__huoji"] = "你可以将一张红色牌当【火攻】使用。你使用的【火攻】效果改为：目标角色随机展示一张手牌，然后你可以弃置一张与此牌"..
  "颜色相同的手牌对其造成1点火焰伤害。",

  ["#ol_ex__huoji"] = "火计：你可以将一张红色牌当【火攻】使用",
  ["#ol_ex__huoji-discard"] = "你可弃置一张 %arg 手牌，对 %src 造成1点火属性伤害",

  ["$ol_ex__huoji1"] = "赤壁借东风，燃火灭魏军。",
  ["$ol_ex__huoji2"] = "东风，让这火烧得再猛烈些吧！",
}

huoji:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "fire_attack",
  prompt = "#ol_ex__huoji",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = huoji.name
    card:addSubcard(cards[1])
    return card
  end,
})

huoji:addEffect(fk.PreCardEffect, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(huoji.name) and data.from == player and data.card.trueName == "fire_attack"
  end,
  on_refresh = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    card.skill = Fk.skills["ol_ex__huoji__fire_attack_skill"]
    data.card = card
  end,
})

return huoji
