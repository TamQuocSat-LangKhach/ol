local fenshu = fk.CreateSkill{
  name = "qin__fenshu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__fenshu"] = "焚书",
  [":qin__fenshu"] = "锁定技，非秦势力角色于其回合内使用的第一张普通锦囊牌无效。",

  ["$qin__fenshu"] = "愚民怎识得天下大智慧？",
}

fenshu:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fenshu.name) and target ~= player and
      target.kingdom ~= "qin" and player.room.current == target and
      data.card:isCommonTrick() and player:usedSkillTimes(fenshu.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    data:removeAllTargets()
    data.toCard = nil
  end,
})

return fenshu
