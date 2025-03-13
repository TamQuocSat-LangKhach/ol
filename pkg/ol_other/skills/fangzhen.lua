local fangzhen = fk.CreateSkill{
  name = "qin__fangzhen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__fangzhen"] = "方阵",
  [":qin__fangzhen"] = "锁定技，当一名非秦势力角色使用【杀】或普通锦囊牌指定你为目标后，若其在你的攻击范围内，"..
  "你判定，若结果为黑色，视为对其使用一张【杀】。",

  ["$qin__fangzhen"] = "步阵而走，方寸之间。"
}

fangzhen:addEffect(fk.TargetConfirmed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fangzhen.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      data.from.kingdom ~= "qin" and player:inMyAttackRange(data.from)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = fangzhen.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge:matchPattern() and not player.dead and not data.from.dead then
      room:useVirtualCard("slash", nil, player, data.from, fangzhen.name, true)
    end
  end,
})

return fangzhen
