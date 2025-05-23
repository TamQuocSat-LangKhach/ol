local skill = fk.CreateSkill {
  name = "#armillary_sphere_skill",
  tags = { Skill.Compulsory },
  attached_equip = "armillary_sphere",
}

Fk:loadTranslationTable{
  ["#armillary_sphere_skill"] = "浑天仪",
}

skill:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.prevented = true
    local cards = table.filter(player:getEquipments(Card.SubtypeTreasure), function (id)
      return Fk:getCardById(id).name == skill.attached_equip
    end)
    room:sendLog{
      type = "#DestructCards",
      card = cards,
    }
    room:moveCardTo(cards, Card.Void, nil, fk.ReasonJustMove, skill.name, nil, true)
  end,
})

skill:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player.dead then return end
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).name == skill.attached_equip then
            return Fk.skills[skill.name]:isEffectable(player)
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = {}
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if info.fromArea == Card.PlayerEquip and card.name == skill.attached_equip and card.number > 0 then
            table.insert(nums, card.number)
          end
        end
      end
    end
    if #nums == 0 then return end
    local ids = {}
    for _, n in ipairs(nums) do
      table.insertTableIfNeed(ids, room:getCardsFromPileByRule(".|"..n.."|.|.|.|trick", 2))
    end
    if #ids > 0 then
      room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, skill.name, nil, false, player)
    end
  end,
})

return skill
