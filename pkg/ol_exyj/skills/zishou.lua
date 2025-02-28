local zishou = fk.CreateSkill{
  name = "ol_ex__zishou",
}

Fk:loadTranslationTable{
  ["ol_ex__zishou"] = "自守",
  [":ol_ex__zishou"] = "摸牌阶段，你可以多摸X张牌，若如此做，本回合结束阶段，若你本回合对其他角色造成过伤害，你弃置X张牌（X为全场势力数）。",
}

zishou:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zishou.name) and target == player
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    data.n = data.n + #kingdoms
  end,
})

zishou:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      return player.phase == Player.Finish and
        player:usedSkillTimes(zishou.name, Player.HistoryTurn) > 0 and
        #player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e)
          local damage = e.data
          return damage.from and damage.from == target and damage.to ~= target
        end, Player.HistoryTurn) > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player.room:askToDiscard(player, {
      min_num = #kingdoms,
      max_num = #kingdoms,
      include_equip = true,
      skill_name = zishou.name,
      cancelable = false,
    })
  end,
})

return zishou