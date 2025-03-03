local skill = fk.CreateSkill {
  name = "#py_double_halberd_skill",
  attached_equip = "py_double_halberd",
}

Fk:loadTranslationTable{
  ["#py_double_halberd_skill"] = "镔铁双戟",
}

skill:addEffect(fk.CardEffectCancelledOut, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card.trueName == "slash" and player.hp > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, skill.name)
    if player.dead then return end
    if room:getCardArea(data.card) == Card.Processing then
      room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, skill.name, nil, true, player)
      if player.dead then return end
    end
    player:drawCards(1, skill.name)
    room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn")
  end,
})

return skill
