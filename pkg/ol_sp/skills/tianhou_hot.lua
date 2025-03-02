local hot = fk.CreateSkill{
  name = "tianhou_hot",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tianhou_hot"] = "烈暑",
  [":tianhou_hot"] = "锁定技，其他角色的结束阶段，若其体力值全场最大，其失去1点体力。",

  ["$tianhou_hot"] = "七月流火，涸我山泽。",
}

hot:addAcquireEffect(function (self, player, is_start)
  player.room:setPlayerMark(player, "@@tianhou_hot", 1)
end)

hot:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@@tianhou_hot", 0)
end)

hot:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(hot.name) and target.phase == Player.Finish and not target.dead and
      table.every(player.room.alive_players, function(p)
        return target.hp >= p.hp
      end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(target, 1, hot.name)
  end,
})

return hot
