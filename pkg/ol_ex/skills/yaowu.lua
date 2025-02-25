local this = fk.CreateSkill{ name = "ol_ex__yaowu" }

this:addEffect(fk.DamageInflicted, {
  mute = true,
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and data.card
  end,
  on_use = function(self, event, target, player, data)
    if data.card.color ~= Card.Red then
      player.room:notifySkillInvoked(player, this.name, "masochism")
      player:broadcastSkillInvoke(this.name, 1)
      player:drawCards(1, this.name)
    else
      if data.from and not data.from.dead then
        player.room:notifySkillInvoked(player, this.name, "negative")
        player:broadcastSkillInvoke(this.name, 2)
        data.from:drawCards(1, this.name)
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__yaowu"] = "耀武",
  [":ol_ex__yaowu"] = "锁定技，当你受到牌造成的伤害时，若造成伤害的牌：为红色，伤害来源摸一张牌；不为红色，你摸一张牌。",
  
  ["$ol_ex__yaowu1"] = "有吾在此，解太师烦忧。",
  ["$ol_ex__yaowu2"] = "这些杂兵，我有何惧！",
}

return this
