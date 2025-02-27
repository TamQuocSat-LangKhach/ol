local wulie = fk.CreateSkill{
  name = "ol_ex__wulie",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["ol_ex__wulie"] = "武烈",
  [":ol_ex__wulie"] = "限定技，结束阶段，你可以失去任意点体力，令等量的其他角色各获得1枚“烈”标记。当有“烈”的角色受到伤害时，其弃所有“烈”，防止此伤害。",

  ["@@ol_ex__wulie_lie"] = "烈",
  ["#ol_ex__wulie-choose"] = "武烈：选择任意名其他角色并失去等量的体力，防止这些角色受到的下次伤害",

  ["$ol_ex__wulie1"] = "孙武之后，英烈勇战。",
  ["$ol_ex__wulie2"] = "兴义之中，忠烈之名。",
}

wulie:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wulie.name) and player.phase == Player.Finish and
      player:usedSkillTimes(wulie.name, Player.HistoryGame) < 1 and player.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = player.hp,
      prompt = "#ol_ex__wulie-choose",
      skill_name = wulie.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, #event:getCostData(self).tos, wulie.name)
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        room:setPlayerMark(p, "@@ol_ex__wulie_lie", 1)
      end
    end
  end,
})

wulie:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@ol_ex__wulie_lie") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
    player.room:setPlayerMark(player, "@@ol_ex__wulie_lie", 0)
  end,
})

return wulie