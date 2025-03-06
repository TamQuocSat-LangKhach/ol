local jiaowei = fk.CreateSkill{
  name = "jiaoweid",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiaoweid"] = "狡威",
  [":jiaoweid"] = "锁定技，你的黑色牌不计入手牌上限。若你的手牌数大于体力值，你对体力值不大于你的角色使用黑色牌无距离限制且不能被这些角色响应。",

  ["$jiaoweid1"] = "巾帼若动起心思，哪还有男人什么事。",
  ["$jiaoweid2"] = "没想到本将军还有这招吧？",
}

jiaowei:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiaowei.name) and player:getHandcardNum() > player.hp and
      data.card.color == Card.Black and (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function(p)
      return p.hp <= player.hp
    end)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(targets) do
      table.insertIfNeed(data.disresponsiveList, p)
    end
  end,
})
jiaowei:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(jiaowei.name) and card.color == Card.Black
  end,
})
jiaowei:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, target)
    if player:hasSkill(jiaowei.name) then
      return card and card.color == Card.Black and target and player.hp >= target.hp
    end
  end,
})

return jiaowei
