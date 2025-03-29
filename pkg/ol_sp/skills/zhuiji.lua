local zhuiji = fk.CreateSkill{
  name = "ol__zhuiji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__zhuiji"] = "追击",
  [":ol__zhuiji"] = "锁定技，你计算与体力值不大于你的角色的距离始终为1。"..
  "当你使用【杀】指定距离为1的角色为目标后，其弃置一张牌或重铸装备区里的所有牌。",

  ["#ol__zhuiji-discard"] = "追击：弃置一张牌，或点“取消”重铸装备区所有牌",
}

zhuiji:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuiji.name) and data.card.trueName == "slash" and
      not data.to.dead and not data.to:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, {data.to})
    local equips = data.to:getCardIds("e")
    local cards = room:askToDiscard(data.to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = zhuiji.name,
      prompt = "#ol__zhuiji-discard",
      cancelable = #equips > 0,
    })
    if #cards == 0 and #equips > 0 then
      room:recastCard(equips, data.to)
    end
  end,
})
zhuiji:addEffect("distance", {
  fixed_func = function(self, from, to)
    if from:hasSkill(zhuiji.name) and from.hp >= to.hp then
      return 1
    end
  end,
})

return zhuiji
