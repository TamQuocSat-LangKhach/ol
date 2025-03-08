local tuoshi = fk.CreateSkill{
  name = "tuoshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tuoshi"] = "侻失",
  [":tuoshi"] = "锁定技，你不能使用【无懈可击】。你使用点数为字母的牌无效并摸一张牌，且下次对手牌数小于你的角色使用牌无距离和次数限制。"..
  "当你一回合内使用过三张未造成过伤害的伤害类牌后，〖嚣翻〗于此回合内失效。",

  ["@@tuoshi"] = "侻失",

  ["$tuoshi1"] = "备者，久居行伍之丘八，何知礼仪？",
  ["$tuoshi2"] = "老革荒悖，可复道邪。",
}

tuoshi:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(tuoshi.name) and
      (data.card.number == 1 or data.card.number > 10)
  end,
  on_use = function (self, event, target, player, data)
    data.toCard = nil
    data:removeAllTargets()
    player.room:setPlayerMark(player, "@@tuoshi", 1)
    player:drawCards(1, tuoshi.name)
  end,
})
tuoshi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:hasSkill(tuoshi.name) and card and card.trueName == "nullification"
  end,
})
tuoshi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:getMark("@@tuoshi") > 0 and to and to:getHandcardNum() < player:getHandcardNum()
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card and player:getMark("@@tuoshi") > 0 and to and to:getHandcardNum() < player:getHandcardNum()
  end,
})
tuoshi:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@tuoshi") > 0 and
      table.find(data.tos, function (p)
        return p:getHandcardNum() < player:getHandcardNum()
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
    player.room:setPlayerMark(player, "@@tuoshi", 0)
  end,
})
tuoshi:addEffect(fk.CardUseFinished, {
  can_refresh = function (self, event, target, player, data)
      return target == player and player:hasSkill(tuoshi.name, true) and
        player:getMark("tuoshi-turn") < 3 and
        data.card.is_damage_card and not data.damageDealt
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "tuoshi-turn")
    if player:getMark("tuoshi-turn") > 2 then
      player.room:invalidateSkill(player, "xiaofan", "-turn")
    end
  end,
})

return tuoshi
