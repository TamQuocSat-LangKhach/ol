local changsheng = fk.CreateSkill{
  name = "qin__changsheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__changsheng"] = "常胜",
  [":qin__changsheng"] = "锁定技，你使用【杀】无距离限制。",

  ["$qin__changsheng"] = "百战百胜，攻无不克！",
}

changsheng:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(changsheng.name) and card and card.trueName == "slash"
  end,
})
changsheng:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(changsheng.name) and
      data.card.trueName == "slash" and
      table.find(data.tos, function (p)
        return not player:inMyAttackRange(p)
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    player:broadcastSkillInvoke(changsheng.name)
    player.room:notifySkillInvoked(player, changsheng.name, "offensive")
  end,
})

return changsheng
