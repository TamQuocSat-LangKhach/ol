local xuanhui = fk.CreateSkill{
  name = "xuanhui",
}

Fk:loadTranslationTable{
  ["xuanhui"] = "旋回",
  [":xuanhui"] = "准备阶段，你可以令本轮其他丰积角色与你交换对应丰积项效果，若如此做，本技能失效直到有角色死亡。",

  ["#xuanhui-invoke"] = "旋回：是否与 %dest 交换丰积效果？",
  ["#xuanhui-choose"] = "旋回：你可以与一名角色交换丰积效果",

  ["$xuanhui1"] = "今日，怕是要辜负温侯美意了。",
  ["$xuanhui2"] = "前盖以惑敌，今图穷而匕见。",
}

xuanhui:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanhui.name) and player.phase == Player.Start and
      (player:getMark("@fengji_draw-round") ~= 0 or player:getMark("@fengji_slash-round") ~= 0) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@fengji_draw-round") ~= 0 or p:getMark("@fengji_slash-round") ~= 0
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:getMark("@fengji_draw-round") ~= 0 or p:getMark("@fengji_slash-round") ~= 0
    end)
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = xuanhui.name,
        prompt = "#xuanhui-invoke::"..targets[1].id,
      }) then
        event:setCostData(self, {tos = targets})
        return true
      end
    else
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = xuanhui.name,
        prompt = "#xuanhui-choose",
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n1, n2 = player:getMark("@fengji_draw-round"), player:getMark("@fengji_slash-round")
    room:setPlayerMark(player, "@fengji_draw-round", to:getMark("@fengji_draw-round"))
    room:setPlayerMark(player, "@fengji_slash-round", to:getMark("@fengji_slash-round"))
    room:setPlayerMark(to, "@fengji_draw-round", n1)
    room:setPlayerMark(to, "@fengji_slash-round", n2)
    room:invalidateSkill(player, xuanhui.name)
  end,
})
xuanhui:addEffect(fk.Deathed, {
  can_refresh = function(self, event, target, player, data)
    return table.contains(player:getTableMark(MarkEnum.InvalidSkills), xuanhui.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:validateSkill(player, xuanhui.name)
  end,
})

return xuanhui
