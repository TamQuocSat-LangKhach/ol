local this = fk.CreateSkill{
  name = "ol_ex__huoji__fire_attack_skill",
  cardSkill = true,
}

this:addEffect("active", {
  prompt = "#fire_attack_skill",
  target_num = 1,
  mod_target_filter = function(_, to_select, _, _, _, _)
    return not to_select:isKongcheng()
  end,
  target_filter = function(self, to_select, selected, _, card, _, player)
    if #selected < self:getMaxTargetNum(Self, card) then
      return self:modTargetFilter(to_select, selected, player, card)
    end
  end,
  on_effect = function(self, room, cardEffectEvent)
    local from = cardEffectEvent.from
    local to = cardEffectEvent.to
    if to:isKongcheng() then return end

    local showCard = table.random(to:getCardIds(Player.Hand))
    to:showCards(showCard)

    if from.dead then return end

    showCard = Fk:getCardById(showCard)
    local pattern = ".|.|no_suit"
    if showCard.color == Card.Red then
      pattern = ".|.|heart,diamond"
    elseif showCard.color == Card.Black then
      pattern = ".|.|spade,club"
    end
    local cards = room:askToDiscard(from, { min_num = 1, max_num = 1, include_equip = false, skill_name = "fire_attack_skill", cancelable = true, pattern = pattern, prompt = "#fire_attack-discard:" .. to.id .. "::" .. showCard:getColorString()})
    if #cards > 0 and not to.dead then
      room:damage({
        from = from,
        to = to,
        card = cardEffectEvent.card,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = "fire_attack_skill"
      })
    end
  end,
})

return this
