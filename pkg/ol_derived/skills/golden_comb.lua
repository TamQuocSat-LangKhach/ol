local skill = fk.CreateSkill {
  name = "#golden_comb_skill",
  tags = { Skill.Compulsory },
  attached_equip = "golden_comb",
}

Fk:loadTranslationTable{
  ["#golden_comb_skill"] = "金梳",
}

skill:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play and
      player:getHandcardNum() < math.min(player:getMaxCards(), 5)
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("zhuangshu", 5)
    player:drawCards(math.min(player:getMaxCards(), 5) - player:getHandcardNum(), skill.name)
  end,
})

return skill
