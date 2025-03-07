local wangong = fk.CreateSkill{
  name = "wangong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["wangong"] = "挽弓",
  [":wangong"] = "锁定技，若你使用的上一张牌是基本牌，你使用【杀】无距离和次数限制且造成的伤害+1。",

  ["@@wangong"] = "挽弓",

  ["$wangong1"] = "强弓挽之，以射长箭！",
  ["$wangong2"] = "挽弓如月，克定江夏！",
}

wangong:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@@wangong", 0)
end)

wangong:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wangong.name) and
      player:getMark("@@wangong") > 0 and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@wangong", 0)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    if not data.extraUse then
      player:addCardUseHistory(data.card.trueName, -1)
      data.extraUse = true
    end
  end,
})
wangong:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(wangong.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@wangong", data.card.type == Card.TypeBasic and 1 or 0)
  end,
})
wangong:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope)
    return player:hasSkill(wangong.name) and player:getMark("@@wangong") > 0 and skill.trueName == "slash_skill" and
      scope == Player.HistoryPhase
  end,
  bypass_distances = function(self, player, skill)
    return player:hasSkill(wangong.name) and player:getMark("@@wangong") > 0 and skill.trueName == "slash_skill"
  end,
})

return wangong
