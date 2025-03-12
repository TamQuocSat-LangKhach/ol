local ximo = fk.CreateSkill{
  name = "ximo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ximo"] = "洗墨",
  [":ximo"] = "锁定技，当你发动〖笔心〗后，移除其描述的前五个字符，若为第三次发动，交换其描述中的两个数字，你失去本技能并获得〖飞白〗。",

  ["$ximo1"] = "帛尽漂洗，以待后用。",
  ["$ximo2"] = "故帛无尽，而笔不停也。",
  ["$ximo3"] = "以帛为纸，临池习书。",
}

ximo:addEffect(fk.AfterSkillEffect, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ximo.name) and data.skill.name == "#bixin_2_trig"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ximo.name)
    local n = player:usedSkillTimes(ximo.name, Player.HistoryGame)
    player:broadcastSkillInvoke(ximo.name, n)
    if n > 2 then
      room:handleAddLoseSkills(player, "-ximo|feibai")
    end
  end,
})

return ximo
