local frost = fk.CreateSkill{
  name = "tianhou_frost",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tianhou_frost"] = "严霜",
  [":tianhou_frost"] = "锁定技，其他角色的结束阶段，若其体力值全场最小，其失去1点体力。",

  ["$tianhou_frost"] = "雪瀑寒霜落，霜下可折竹。",
}

frost:addAcquireEffect(function (self, player, is_start)
  player.room:setPlayerMark(player, "@@tianhou_frost", 1)
end)

frost:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@@tianhou_frost", 0)
end)

frost:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(frost.name) and target.phase == Player.Finish and not target.dead and
      table.every(player.room.alive_players, function(p)
        return target.hp <= p.hp
      end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(target, 1, frost.name)
  end,
})

return frost
