local liangju = fk.CreateSkill{
  name = "qin__liangju",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__liangju"] = "良驹",
  [":qin__liangju"] = "锁定技，你使用【杀】指定后，其判定，若结果为<font color='red'>♦</font>，其不能使用【闪】响应；"..
  "当你成为【杀】的目标后，你判定，若结果为<font color='red'>♥</font>，此【杀】对你无效。",

  ["$qin__liangju"] = "良驹千里，踏遍河山"
}

liangju:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liangju.name) and data.card.trueName == "slash" and
      not data.to.dead
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local judge = {
      who = data.to,
      reason = liangju.name,
      pattern = ".|.|diamond",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data.use.unoffsetableList = data.use.unoffsetableList or {}
      table.insertIfNeed(data.use.unoffsetableList, data.to)
    end
  end,
})
liangju:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liangju.name) and data.card.trueName == "slash"
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = liangju.name,
      pattern = ".|.|heart",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data.nullified = true
    end
  end,
})

return liangju
