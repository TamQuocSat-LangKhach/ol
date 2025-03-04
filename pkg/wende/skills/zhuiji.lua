local zhuiji = fk.CreateSkill{
  name = "zhuijix",
}

Fk:loadTranslationTable{
  ["zhuijix"] = "追姬",
  [":zhuijix"] = "出牌阶段开始时，你可以选择一项：1.回复1点体力，并于此阶段结束时弃置两张牌；2.摸两张牌，并于此阶段结束时失去1点体力。",

  ["zhuijix_recover"] = "回复1点体力，此阶段结束时弃两张牌",
  ["zhuijix_draw"] = "摸两张牌，此阶段结束时失去1点体力",

  ["$zhuijix1"] = "不过是些微代价罢了。",
  ["$zhuijix2"] = "哼，以为这就能难倒我吗？",
}

zhuiji:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuiji.name) and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local all_choices = {"zhuijix_recover", "zhuijix_draw", "Cancel"}
    local choices = table.simpleClone(all_choices)
    if not player:isWounded() then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhuiji.name,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:setPlayerMark(player, choice.."-phase", 1)
    if choice == "zhuijix_recover" then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = zhuiji.name,
      }
    else
      player:drawCards(2, zhuiji.name)
    end
  end,
})
zhuiji:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      player:usedSkillTimes(zhuiji.name, Player.HistoryPhase) > 0 and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("zhuijix_recover-phase") > 0 then
      room:setPlayerMark(player, "zhuiji_recover-phase", 0)
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = zhuiji.name,
        cancelable = false,
      })
    end
    if player:getMark("zhuijix_draw-phase") > 0 then
      room:setPlayerMark(player, "zhuiji_draw-phase", 0)
      room:loseHp(player, 1, zhuiji.name)
    end
  end,
})

return zhuiji
