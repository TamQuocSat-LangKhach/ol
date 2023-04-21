-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("variation", Package.CardPack)

local slash = Fk:cloneCard("slash")
local iceSlashSkill = fk.CreateActiveSkill{
  name = "ice__slash_skill",
  max_phase_use_time = 1,
  target_num = 1,
  can_use = slash.skill.canUse,
  target_filter = slash.skill.targetFilter,
  on_effect = function(self, room, effect)
    local to = effect.to
    local from = effect.from

    room:damage({
      from = room:getPlayerById(from),
      to = room:getPlayerById(to),
      card = effect.card,
      damage = 1 + (effect.additionalDamage or 0),
      damageType = fk.IceDamage,
      skillName = self.name
    })
  end
}
local iceSlash = fk.CreateBasicCard{
  name = "ice__slash",
  skill = iceSlashSkill,
  is_damage_card = true,
}
extension:addCards{
  iceSlash:clone(Card.Spade, 7),
  iceSlash:clone(Card.Spade, 7),
  iceSlash:clone(Card.Spade, 8),
  iceSlash:clone(Card.Spade, 8),
  iceSlash:clone(Card.Spade, 8),
}

local unexpectationSkill = fk.CreateActiveSkill{
  name = "unexpectation_skill",
  target_num = 1,
  target_filter = function(self, to_select)
    return to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if to:isKongcheng() then return end
    local showCard = room:askForCardChosen(from, to, "h", self.name)
    to:showCards(showCard)
    showCard = Fk:getCardById(showCard)
    if showCard.suit == Card.NoSuit or effect.card.suit == Card.NoSuit then return end
    if showCard.suit ~= effect.card.suit then
      room:damage({
        from = from,
        to = to,
        card = effect.card,
        damage = 1,
        skillName = self.name
      })
    end
  end,
}
local unexpectation = fk.CreateTrickCard{
  name = "unexpectation",
  skill = unexpectationSkill,
  is_damage_card = true,
}
extension:addCards{
  unexpectation:clone(Card.Heart, 3),
  unexpectation:clone(Card.Diamond, 11),
}

local foresightSkill = fk.CreateActiveSkill{
  name = "foresight_skill",
  on_use = function(self, room, cardUseEvent)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = {{cardUseEvent.from}}
    end
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    room:askForGuanxing(to, room:getNCards(2))
    room:drawCards(to, 2, self.name)
  end
}
local foresight = fk.CreateTrickCard{
  name = "foresight",
  skill = foresightSkill,
}
extension:addCards({
  foresight:clone(Card.Heart, 7),
  foresight:clone(Card.Heart, 8),
  foresight:clone(Card.Heart, 9),
  foresight:clone(Card.Heart, 11),
})

Fk:loadTranslationTable{
  ["variation"] = "应变",

  ["ice__slash"] = "冰杀",
  ["unexpectation"] = "出其不意",
  ["unexpectation_skill"] = "出其不意",
  ["foresight"] = "洞烛先机",
  ["foresight_skill"] = "洞烛先机",
  ["chasing_near"] = "逐近弃远",
  ["drowning"] = "水淹七军",
  ["adaptation"] = "随机应变",
}

return extension
