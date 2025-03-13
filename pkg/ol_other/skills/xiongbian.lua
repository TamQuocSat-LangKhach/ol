local xiongbian = fk.CreateSkill{
  name = "qin__xiongbian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__xiongbian"] = "雄辩",
  [":qin__xiongbian"] = "锁定技，当你成为普通锦囊牌的目标时，你判定，若点数为6，此牌无效。",

  ["$qin__xiongbian"] = "据坛雄辩，无人可驳！",
}

xiongbian:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiongbian.name) and data.card:isCommonTrick()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = xiongbian.name,
      pattern = ".|6",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data:cancelTarget(player)
    end
  end,
})

return xiongbian
