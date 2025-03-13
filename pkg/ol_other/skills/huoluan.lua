local huoluan = fk.CreateSkill{
  name = "qin__huoluan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__huoluan"] = "祸乱",
  [":qin__huoluan"] = "锁定技，当你发动〖大期〗的回复效果和摸牌效果后，你对所有其他角色各造成1点伤害。",

  ["$qin__huoluan"] = "这天下都是我的，我有什么不能做的？",
}

huoluan:addEffect(fk.AfterSkillEffect, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huoluan.name) and
      (data.skill.name == "qin__daqi" or data.skill.name == "qin__xianji")
  end,
  on_cost = function (self, event, target, player, data)
    local targets = player.room:getOtherPlayers(player)
    event:setCostData(self, {tos = targets})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = huoluan.name,
        }
      end
    end
  end,
})

return huoluan
