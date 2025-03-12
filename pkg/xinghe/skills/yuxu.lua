local yuxu = fk.CreateSkill{
  name = "yuxu",
}

Fk:loadTranslationTable{
  ["yuxu"] = "誉虚",
  [":yuxu"] = "当你于出牌阶段内使用牌结算后，你可以摸一张牌，若如此做，当你此阶段使用下一张牌后，你弃置一张牌。",

  ["#yuxu-invoke"] = "誉虚：你可以摸一张牌，然后你使用下一张牌后需弃置一张牌",

  ["$yuxu1"] = "誉名浮虚，播流四海。",
  ["$yuxu2"] = "誉虚之名，得保一时。",
}

yuxu:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuxu.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player:usedSkillTimes(yuxu.name, Player.HistoryPhase) % 2 == 1 or
      player.room:askToSkillInvoke(player, {
        skill_name = yuxu.name,
        prompt = "#yuxu-invoke",
      })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:usedSkillTimes(yuxu.name, Player.HistoryPhase) % 2 == 1 then
      player:drawCards(1, yuxu.name)
    else
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = yuxu.name,
        cancelable = false,
      })
    end
  end,
})

return yuxu
