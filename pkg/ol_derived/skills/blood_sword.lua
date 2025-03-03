local skill = fk.CreateSkill {
  name = "#blood_sword_skill",
  tags = { Skill.Compulsory },
  attached_equip = "blood_sword",
}

Fk:loadTranslationTable{
  ["#blood_sword_skill"] = "赤血青锋",
}

skill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card and data.card.trueName == "slash" and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    data.to:addQinggangTag(data)
    player.room:addPlayerMark(data.to, skill.name)
    data.extra_data = data.extra_data or {}
    data.extra_data.blood_sword = data.extra_data.blood_sword or {}
    data.extra_data.blood_sword[tostring(data.to.id)] = (data.extra_data.blood_sword[tostring(data.to.id)] or 0) + 1
  end,
})
skill:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.blood_sword
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.blood_sword) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(skill.name) > 0 then
        room:removePlayerMark(p, skill.name, num)
      end
    end
  end,
})
skill:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark(skill.name) > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark(skill.name) > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})

return skill
