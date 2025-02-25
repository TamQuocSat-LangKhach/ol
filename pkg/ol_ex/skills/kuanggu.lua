local this = fk.CreateSkill{ name = "ol_ex__kuanggu" }

this:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(this.name) and target == player and (data.extra_data or {}).kuanggucheck
  end,
  on_trigger = function(self, event, target, player, data)
    for i = 1, data.damage do
      if i > 1 and (self.cost_data == "Cancel" or not player:hasSkill(this.name)) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1", "Cancel"}
    if player:isWounded() then
      table.insert(choices, 2, "recover")
    end
    self.cost_data = room:askToChoice(player, { choices = choices, skill_name = this.name})
    return self.cost_data ~= "Cancel"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "recover" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = this.name
      })
    elseif self.cost_data == "draw1" then
      player:drawCards(1, this.name)
    end
  end,
})

this:addEffect(fk.BeforeHpChanged, {
  can_refresh = function(self, event, target, player, data)
    if data.damageEvent and player == data.damageEvent.from and player:distanceTo(target) < 2 and not target:isRemoved() then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageEvent.extra_data = data.damageEvent.extra_data or {}
    data.damageEvent.extra_data.kuanggucheck = true
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__kuanggu"] = "狂骨",
  [":ol_ex__kuanggu"] = "你对距离1以内的角色造成1点伤害后，你可以选择摸一张牌或回复1点体力。",
  
  ["$ol_ex__kuanggu1"] = "反骨狂傲，彰显本色！",
  ["$ol_ex__kuanggu2"] = "只有战场，能让我感到兴奋！",
}

return this