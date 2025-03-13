local chouniu = fk.CreateSkill{
  name = "shengxiao_chouniu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shengxiao_chouniu"] = "丑牛",
  [":shengxiao_chouniu"] = "锁定技，每名角色的结束阶段，若你的体力值全场最小，你回复1点体力。",
}

chouniu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(chouniu.name) and target.phase == Player.Finish and
      player:isWounded() and
      table.every(player.room.alive_players, function (p)
        return p.hp >= player.hp
      end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = chouniu.name,
    }
  end,
})

return chouniu
