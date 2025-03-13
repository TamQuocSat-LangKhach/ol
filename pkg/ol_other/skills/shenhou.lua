local shenhou = fk.CreateSkill{
  name = "shengxiao_shenhou",
}

Fk:loadTranslationTable{
  ["shengxiao_shenhou"] = "申猴",
  [":shengxiao_shenhou"] = "当你成为【杀】的目标后，你可以判定，若结果为红色，此【杀】对你无效。",
}

shenhou:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shenhou.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = shenhou.name,
      pattern = ".|.|heart,diamond",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data.nullified = true
    end
  end,
})

return shenhou
