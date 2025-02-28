local duoshou = fk.CreateSkill{
  name = "duoshou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["duoshou"] = "夺首",
  [":duoshou"] = "锁定技，每回合你首次使用红色牌无距离限制、首次使用基本牌不计入限制的次数、首次造成伤害后摸一张牌。",

  ["$duoshou1"] = "今日之敌，必死于我刀下！",
  ["$duoshou2"] = "青龙所向，战无不胜！",
}

duoshou:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duoshou.name) and
      ((player:getMark("duoshou_red-turn") == 0 and data.card.color == Card.Red) or
      (player:getMark("duoshou_basic-turn") == 0 and data.card.type == Card.TypeBasic))
  end,
  on_use = function(self, event, target, player, data)
    if data.card.color == Card.Red then
      player.room:setPlayerMark(player, "duoshou_red-turn", 1)
    end
    if data.card.type == Card.TypeBasic then
      player.room:setPlayerMark(player, "duoshou_basic-turn", 1)
      if not data.extraUse then
        data.extraUse = true
        player:addCardUseHistory(data.card.trueName, -1)
      end
    end
  end,
})
duoshou:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duoshou.name) and
      player:getMark("duoshou_damage-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "duoshou_damage-turn", 1)
    player:drawCards(1, duoshou.name)
  end,
})
duoshou:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(duoshou.name) and card and card.color == Card.Red and player:getMark("duoshou_red-turn") == 0
  end,
})

return duoshou
