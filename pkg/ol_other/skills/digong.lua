local digong = fk.CreateSkill{
  name = "digong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["digong"] = "地公",
  [":digong"] = "锁定技，当你使用非本轮获得的牌时，若为伤害牌，此牌伤害+1；若不为伤害牌，结算后当前回合角色进行判定，若为红色，你摸一张牌。",

  ["@@digong-inhand-round"] = "地公",

  ["$digong1"] = "太平气出，今为元气纯纯之时！",
  ["$digong2"] = "与道召道，以道求道，以道为兄弟。",
}

digong:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(digong.name) and
      data.card.is_damage_card and data.extra_data and data.extra_data.digong
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

digong:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(digong.name) and
      not data.card.is_damage_card and data.extra_data and data.extra_data.digong and
      not player.room.current.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = room.current,
      reason = digong.name,
      pattern = ".|.|heart,diamond",
    }
    room:judge(judge)
    if judge:matchPattern() and not player.dead then
      player:drawCards(1, digong.name)
    end
  end,
})

digong:addEffect(fk.RoundStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(digong.name, true) and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), "@@digong-inhand-round", 1)
    end
  end,
})

digong:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(digong.name, true) and
      data.card:getMark("@@digong-inhand-round") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.digong = true
  end,
})

digong:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id), "@@digong-inhand-round", 0)
  end
end)

return digong
