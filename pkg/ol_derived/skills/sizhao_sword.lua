local skill = fk.CreateSkill {
  name = "#sizhao_sword_skill",
  tags = { Skill.Compulsory },
  attached_equip = "sizhao_sword",
}

Fk:loadTranslationTable{
  ["#sizhao_sword_skill"] = "思召剑",
}

skill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card.trueName == "slash" and data.card.number > 0
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.sizhao_number = data.card.number
  end,
})
skill:addEffect(fk.HandleAskForPlayCard, {
  can_refresh = function(self, event, target, player, data)
    return data.eventData and data.eventData.from == player and (data.eventData.extra_data or {}).sizhao_number
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if not data.afterRequest then
      room:setBanner("sizhao_number", data.eventData.extra_data.sizhao_number)
    else
      room:setBanner("sizhao_number", 0)
    end
  end,
})
skill:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local number = Fk:currentRoom():getBanner("sizhao_number")
    if number and number > 0 then
      return card.name == "jink" and card.number > 0 and card.number < number
    end
  end,
})

return skill
