local sk = fk.CreateSkill {
  name = "#qin_crossbow_skill",
  tags = { Skill.Compulsory },
  attached_equip = "qin_crossbow",
}

Fk:loadTranslationTable{
  ["#qin_crossbow_skill"] = "秦弩",
}

sk:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sk.name) and data.card and data.card.trueName == "slash" and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})
sk:addEffect("targetmod", {
  residue_func = function (self, player, skill, scope, card, to)
    if player:hasSkill(sk.name) and card and card.trueName == "slash" and scope == Player.HistoryPhase then
      local cardIds = Card:getIdList(card)
      local crossbows = table.filter(player:getEquipments(Card.SubtypeWeapon), function(id)
        return Fk:getCardById(id).name == sk.attached_equip
      end)
      if #crossbows == 0 or not table.every(crossbows, function(id)
        return table.contains(cardIds, id)
      end) then
        return 1
      end
    end
  end,
})

return sk
