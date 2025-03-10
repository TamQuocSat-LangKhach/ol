local zhuitao = fk.CreateSkill{
  name = "zhuitao",
}

Fk:loadTranslationTable{
  ["zhuitao"] = "追讨",
  [":zhuitao"] = "准备阶段，你可以令你与一名未以此法减少距离的其他角色的距离-1。当你对其造成伤害后，失去你以此法对其减少的距离。",

  ["#zhuitao-choose"] = "追讨：选择一名角色，你至其距离-1直到你对其造成伤害",

  ["$zhuitao1"] = "敌将休走，汝命休矣！",
  ["$zhuitao2"] = "长缨在手，敌寇何逃！",
}

zhuitao:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuitao.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not table.contains(player:getTableMark(zhuitao.name), p.id)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not table.contains(player:getTableMark(zhuitao.name), p.id)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhuitao.name,
      prompt = "#zhuitao-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMark(player, zhuitao.name, to.id)
  end,
})
zhuitao:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(player:getTableMark(zhuitao.name), data.to.id)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:removeTableMark(player, zhuitao.name, data.to.id)
  end,
})
zhuitao:addEffect("distance", {
  correct_func = function(self, from, to)
    if table.contains(from:getTableMark(zhuitao.name), to.id) then
      return -1
    end
  end,
})

return zhuitao
