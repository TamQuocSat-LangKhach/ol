local yitong = fk.CreateSkill{
  name = "qin__yitong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__yitong"] = "一统",
  [":qin__yitong"] = "锁定技，你使用【杀】、【过河拆桥】、【顺手牵羊】、【火攻】无距离限制且改为指定所有非秦势力角色为目标。",

  ["$qin__yitong"] = "秦得一统，安乐升平！",
}

yitong:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yitong.name) and
      table.contains({"slash", "dismantlement", "snatch", "fire_attack"}, data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return p.kingdom ~= "qin" and not player:isProhibited(p, data.card) and
        data.card.skill:modTargetFilter(player, p, {}, data.card, data.extra_data or {bypass_distances = true})
    end)
    room:doIndicate(player, targets)
    data.tos = targets
  end,
})
yitong:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(yitong.name) and card and
      table.contains({"slash", "dismantlement", "snatch", "fire_attack"}, card.trueName)
  end,
})
yitong:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return from:hasSkill(yitong.name) and card and
      table.contains({"slash", "dismantlement", "snatch", "fire_attack"}, card.trueName) and
      to.kingdom == "qin"
  end,
})

return yitong
