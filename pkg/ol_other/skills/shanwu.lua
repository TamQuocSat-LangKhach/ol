local shanwu = fk.CreateSkill{
  name = "qin__shanwu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__shanwu"] = "善舞",
  [":qin__shanwu"] = "锁定技，当你使用【杀】指定目标后，你判定，若为黑色，此【杀】不能被【闪】抵消；"..
  "当你成为【杀】的目标后，你判定，若为红色，此【杀】无效。",

  ["$qin__shanwu"] = "妾身跳的舞，将军爱看吗？",
}

shanwu:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanwu.name) and data.card.trueName == "slash"
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = shanwu.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data.unoffsetable = true
    end
  end,
})
shanwu:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanwu.name) and data.card.trueName == "slash"
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = shanwu.name,
      pattern = ".|.|heart,diamond",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data.use.nullifiedTargets = room.players
    end
  end,
})

return shanwu
