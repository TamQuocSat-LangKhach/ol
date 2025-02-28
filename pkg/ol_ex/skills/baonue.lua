local baonue = fk.CreateSkill{
  name = "ol_ex__baonue",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["ol_ex__baonue"] = "暴虐",
  [":ol_ex__baonue"] = "主公技，当其他群雄角色造成1点伤害后，你可以判定，若结果为♠，你获得判定牌并回复1点体力。",

  ["$ol_ex__baonue1"] = "吾乃人屠，当以兵为贡。",
  ["$ol_ex__baonue2"] = "天下群雄，唯我独尊！",
}

baonue:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(baonue.name) and target and player ~= target and target.kingdom == "qun"
  end,
  on_trigger = function(self, event, target, player, data)
    for i = 1, data.damage do
      if i > 1 and (event:isCancelCost(self) or not player:hasSkill(baonue.name)) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = baonue.name,
    }) then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = baonue.name,
      pattern = ".|.|spade",
    }
    room:judge(judge)
    if judge:matchPattern() and player:isWounded() and not player.dead then
      room:recover({
        who = player,
        num = 1,
        recoverBy = target,
        skillName = baonue.name,
      })
    end
  end
})

baonue:addEffect(fk.FinishJudge, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.suit == Card.Spade and data.reason == baonue.name
      and player.room:getCardArea(data.card.id) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, baonue.name)
  end,
})

return baonue