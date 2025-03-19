local skill = fk.CreateSkill {
  name = "#qin_dragon_sword_skill",
  tags = { Skill.Compulsory },
  attached_equip = "qin_dragon_sword",
}

Fk:loadTranslationTable{
  ["#qin_dragon_sword_skill"] = "真龙长剑",
}

skill:addEffect(fk.AfterCardUseDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card:isCommonTrick() and
      player:usedSkillTimes(skill.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    data.unoffsetableList = table.simpleClone(player.room.players)
  end,
})

return skill
