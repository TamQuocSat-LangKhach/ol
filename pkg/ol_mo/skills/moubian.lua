local moubian = fk.CreateSkill{
  name = "moubian",
}

Fk:loadTranslationTable{
  ["moubian"] = "谋变",
  [":moubian"] = "准备阶段，若你的“诡伏”记录不小于3，你可以<a href=':be_evil'>入魔</a>，获得记录的技能，然后获得技能〖骤袭〗。",

  ["be_evil"] = "入魔",
  [":be_evil"] = "每轮结束时，若你本轮未造成过伤害，你失去1点体力。",

  ["$moubian1"] = "别跟我谈什么对错！我的灵魂，即是我的正义！",
  ["$moubian2"] = "我这把剑，该见见血了！",
  ["$moubian3"] = "无天无界，我就是天命！",
  ["$moubian4"] = "自今日起，我剑由我不由人！",
}

moubian:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(moubian.name) and player.phase == Player.Start and
      player:usedSkillTimes(moubian.name, Player.HistoryGame) == 0 and
      (#player:getTableMark("guifu_card_record") + #player:getTableMark("guifu_skill_record")) > 2
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local skills = player:getTableMark("guifu_skill_record")
    table.insert(skills, "zhouxi")
    room:handleAddLoseSkills(player, table.concat(skills, "|"))
  end,
})

moubian:addEffect(fk.RoundEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return not player.dead and
      player:usedSkillTimes(moubian.name, Player.HistoryGame) > 0 and
      --player:usedSkillTimes(moubian.name, Player.HistoryRound) == 0 and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player
      end, Player.HistoryRound) == 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 1, moubian.name)
  end,
})

return moubian