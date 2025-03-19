local taihou = fk.CreateSkill{
  name = "qin__taihou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__taihou"] = "太后",
  [":qin__taihou"] = "锁定技，当你成为男性角色使用的【杀】或普通锦囊牌的目标时，其需弃置一张相同类别的牌，否则此牌无效。",

  ["#qin__taihou-card"] = "太后：你须弃置一张%arg，否则此%arg2无效",

  ["$qin__taihou"] = "本太后在此，岂容汝等放肆！",
}

taihou:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(taihou.name) and
      (data.card:isCommonTrick() or data.card.trueName == "slash") and
      data.from:isMale()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from.dead or data.from:isNude() or
      #room:askToDiscard(data.from, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = taihou.name,
        pattern = ".|.|.|.|.|"..data.card:getTypeString(),
        prompt = "#qin__taihou-card:::"..data.card:getTypeString()..":"..data.card:toLogString(),
        cancelable = true,
      }) == 0 then
      data.use.nullifiedTargets = table.simpleClone(room.players)
    end
  end,
})

return taihou
