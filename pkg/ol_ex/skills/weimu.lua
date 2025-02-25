local this = fk.CreateSkill {
  name = "ol_ex__weimu",
  frequency = Skill.Compulsory,
}

this:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and player.room.current == player
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(data.damage*2, this.name)
    return true
  end,
})

this:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    return to:hasSkill(this.name) and card.type == Card.TypeTrick and card.color == Card.Black
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__weimu"] = "帷幕",
  [":ol_ex__weimu"] = "锁定技，①你不是黑色锦囊牌的合法目标。②当你于回合内受到伤害时，你防止此伤害，摸2X张牌（X为伤害值）。",

  ["$ol_ex__weimu1"] = "此伤与我无关。",
  ["$ol_ex__weimu2"] = "还是另寻他法吧。",
}

return this