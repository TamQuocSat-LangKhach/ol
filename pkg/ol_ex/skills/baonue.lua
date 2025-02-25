local this = fk.CreateSkill{
  name = "ol_ex__baonue$",
}

this:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(this.name) and player ~= target and target.kingdom == "qun"
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if i > 1 and (self.cancel_cost or not player:hasSkill(this.name)) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, { skill_name = self.name, data = data}) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|spade",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = target,
        skillName = self.name
      })
    end
  end
})

this:addEffect(fk.FinishJudge, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.suit == Card.Spade and data.reason == self.name
      and player.room:getCardArea(data.card.id) == Card.Processing
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player.id, data.card, true)
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__baonue"] = "暴虐",
  [":ol_ex__baonue"] = "主公技，当其他群雄角色造成1点伤害后，你可判定，若结果为♠，回复1点体力，然后当判定牌生效后，你获得此牌。",
  
  ["$ol_ex__baonue1"] = "吾乃人屠，当以兵为贡。",
  ["$ol_ex__baonue2"] = "天下群雄，唯我独尊！",
}

return this