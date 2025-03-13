local fachu = fk.CreateSkill{
  name = "qin__fachu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__fachu"] = "伐楚",
  [":qin__fachu"] = "锁定技，你造成伤害使非秦势力角色进入濒死状态后，随机废除其一个装备栏。",

  ["$qin__fachu"] = "兴兵伐楚，稳大秦基业！",
}

fachu:addEffect(fk.EnterDying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fachu.name) and target ~= player and data.damage and data.damage.from == player and
      target.kingdom ~= "qin" and #target:getAvailableEquipSlots() > 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:abortPlayerArea(target, {table.random(target:getAvailableEquipSlots())})
  end,
})

return fachu
