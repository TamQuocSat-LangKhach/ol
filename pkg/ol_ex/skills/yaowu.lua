local yaowu = fk.CreateSkill{
  name = "ol_ex__yaowu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_ex__yaowu"] = "耀武",
  [":ol_ex__yaowu"] = "锁定技，当你受到牌造成的伤害时，若造成伤害的牌：为红色，伤害来源摸一张牌；不为红色，你摸一张牌。",

  ["$ol_ex__yaowu1"] = "有吾在此，解太师烦忧。",
  ["$ol_ex__yaowu2"] = "这些杂兵，我有何惧！",
}

yaowu:addEffect(fk.DamageInflicted, {
  mute = true,
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(yaowu.name) and data.card then
      if data.card.color ~= Card.Red then
        return true
      else
        return data.from and not data.from.dead
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if data.card.color ~= Card.Red then
      player.room:notifySkillInvoked(player, yaowu.name, "masochism")
      player:broadcastSkillInvoke(yaowu.name, 1)
      player:drawCards(1, yaowu.name)
    else
      player.room:notifySkillInvoked(player, yaowu.name, "negative")
      player:broadcastSkillInvoke(yaowu.name, 2)
      data.from:drawCards(1, yaowu.name)
    end
  end,
})

return yaowu
