local shengzhi = fk.CreateSkill{
  name = "shengzhi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shengzhi"] = "圣质",
  [":shengzhi"] = "锁定技，当你发动非锁定技后，你本回合使用的下一张牌无距离和次数限制。",

  ["@@shengzhi-turn"] = "圣质",

  ["$shengzhi1"] = "位继父兄，承弘德以继往。",
  ["$shengzhi2"] = "英魂犹在，履功业而开来。",
}

shengzhi:addEffect(fk.AfterSkillEffect, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shengzhi.name) and
      not data.skill:hasTag(Skill.Compulsory) and
      not (data.skill.cardSkill or data.skill.global) and data.skill:isPlayerSkill(target) and
      not data.skill.is_delay_effect
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@shengzhi-turn", 1)
  end,
})
shengzhi:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@shengzhi-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, shengzhi.name)
    player:broadcastSkillInvoke(shengzhi.name)
    player.room:setPlayerMark(player, "@@shengzhi-turn", 0)
    if not data.extraUse then
      target:addCardUseHistory(data.card.trueName, -1)
      data.extraUse = true
    end
  end,
})
shengzhi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:getMark("@@shengzhi-turn") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card and player:getMark("@@shengzhi-turn") > 0
  end,
})

return shengzhi
