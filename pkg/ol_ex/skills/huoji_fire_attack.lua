local fire_attack = fk.CreateSkill{
  name = "ol_ex__huoji__fire_attack_skill",
}

Fk:loadTranslationTable{
  ["ol_ex__huoji__fire_attack_skill"] = "眩惑",
}

fire_attack:addEffect("cardskill", {
  prompt = "#fire_attack_skill",
  can_use = Util.CanUse,
  target_num = 1,
  mod_target_filter = function(self, _, to_select, _, _, _)
    return not to_select:isKongcheng()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if to:isKongcheng() then return end

    local showCard = table.random(to:getCardIds("h"))
    to:showCards(showCard)

    showCard = Fk:getCardById(showCard)

    local pattern = showCard.color == Card.Red and ".|.|heart,diamond" or ".|.|spade,club"

    local params = { ---@type AskToDiscardParams
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fire_attack.name,
      cancelable = true,
      pattern = pattern,
      prompt = "#ol_ex__huoji-discard:" .. to.id .. "::" .. showCard:getColorString()
    }
    local cards = room:askToDiscard(from, params)
    if #cards > 0 and not to.dead then
      room:damage{
        from = from,
        to = to,
        card = effect.card,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = "fire_attack_skill",
      }
    end
  end,
})

return fire_attack
