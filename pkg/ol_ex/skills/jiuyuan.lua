local jiuyuan = fk.CreateSkill{
  name = "ol_ex__jiuyuan",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["ol_ex__jiuyuan"] = "救援",
  [":ol_ex__jiuyuan"] = "主公技，其他吴势力角色于其回合内回复体力时，若其体力值不小于你，则其可以改为令你回复1点体力，然后其摸一张牌。",

  ["#ol_ex__jiuyuan-ask"] = "救援：你可以改为令 %dest 回复1点体力，然后你摸一张牌",

  ["$ol_ex__jiuyuan1"] = "多谢爱卿了。",
  ["$ol_ex__jiuyuan2"] = "贤臣良将在，我心安已。",
}

jiuyuan:addEffect(fk.PreHpRecover, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(jiuyuan.name) and
      target.kingdom == "wu" and player.room.current == target and
      target.hp >= player.hp and player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(target, {
      skill_name = jiuyuan.name,
      prompt = "#ex__jiuyuan-ask::"..player.id,
    }) then
      room:doIndicate(target, {player})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:preventRecover()
    player.room:recover{
      who = player,
      num = 1,
      skillName = jiuyuan.name,
      recoverBy = target,
    }
    if not target.dead then
      target:drawCards(1, jiuyuan.name)
    end
  end,
})

return jiuyuan
