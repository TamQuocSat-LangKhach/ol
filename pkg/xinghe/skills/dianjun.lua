local dianjun = fk.CreateSkill{
  name = "dianjun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dianjun"] = "殿军",
  [":dianjun"] = "锁定技，结束阶段结束时，你受到1点伤害并执行一个额外的出牌阶段。",

  ["$dianjun1"] = "大将军勿忧，翼可领后军。",
  ["$dianjun2"] = "诸将速行，某自领军殿后！",
}

dianjun:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dianjun.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player,
      damage = 1,
      skillName = dianjun.name,
    }
    if player.dead then return false end
    player:gainAnExtraPhase(Player.Play, dianjun.name)
  end,
})

return dianjun
