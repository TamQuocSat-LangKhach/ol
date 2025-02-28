local hunzi = fk.CreateSkill {
  name = "ol_ex__hunzi",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable {
  ["ol_ex__hunzi"] = "魂姿",
  [":ol_ex__hunzi"] = "觉醒技，准备阶段，若你的体力值为1，你减1点体力上限，获得〖英姿〗和〖英魂〗。本回合结束阶段，你摸两张牌或回复1点体力。",

  ["$ol_ex__hunzi1"] = "江东新秀，由此崛起。",
  ["$ol_ex__hunzi2"] = "看汝等大展英气！",
}

hunzi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hunzi.name) and
      player:usedEffectTimes(hunzi.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player.hp == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "ex__yingzi|yinghun")
  end,
})

hunzi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and not player.dead and
      player:usedEffectTimes(hunzi.name, Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = hunzi.name,
      prompt = "#ol_ex__hunzi-choice",
    })
    if choice == "draw2" then
      player:drawCards(2, hunzi.name)
    else
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = hunzi.name,
      }
    end
  end,
})

return hunzi