local duanbing = fk.CreateSkill{
  name = "ol__duanbing",
}

Fk:loadTranslationTable{
  ["ol__duanbing"] = "短兵",
  [":ol__duanbing"] = "你使用【杀】时可以多选择一名距离为1的角色为目标；你对距离为1的角色使用【杀】需要两张【闪】才能抵消。",

  ["#ol__duanbing-choose"] = "短兵：你可以额外选择一名距离为1的角色为此【杀】目标",

  ["$ol__duanbing1"] = "弃马，亮兵器，杀！",
  ["$ol__duanbing2"] = "雪中奋短兵，快者胜！",
}

duanbing:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duanbing.name) and data.card.trueName == "slash" and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:distanceTo(p) == 1 and table.contains(data:getExtraTargets(), p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:distanceTo(p) == 1 and table.contains(data:getExtraTargets(), p)
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = duanbing.name,
      prompt = "#ol__duanbing-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})
duanbing:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duanbing.name) and data.card.trueName == "slash" and
      player:distanceTo(data.to) == 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data.fixedResponseTimes = 2
    data.fixedAddTimesResponsors = data.fixedAddTimesResponsors or {}
    table.insertIfNeed(data.fixedAddTimesResponsors, data.to)
  end,
})

return duanbing
