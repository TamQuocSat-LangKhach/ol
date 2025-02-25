local this = fk.CreateSkill{
  name = "ol_ex__jieming",
}

this:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(this.name) and player == target
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if i > 1 and (self.cancel_cost or not player:hasSkill(this.name)) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, { targets = player.room:getAlivePlayers(), min_num = 1, max_num = 1, prompt = "#ol_ex__jieming-choose", skill_name = this.name, cancelable = true})
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local to = self.cost_data
    to:drawCards(math.min(to.maxHp, 5), this.name)
    if to.dead then return false end
    local x = #to.player_cards[Player.Hand] - math.min(to.maxHp, 5)
    if x > 0 then
      player.room:askToDiscard(to, { min_num = x, max_num = x, include_equip = false, skill_name = this.name, cancelable = false, pattern = ".", prompt = "#ol_ex__jieming-discard:::"..x})
    end
  end,
})

this:addEffect(fk.Death, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, { targets = player.room:getAlivePlayers(), min_num = 1, max_num = 1, prompt = "#ol_ex__jieming-choose", skill_name = this.name, cancelable = true})
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local to = self.cost_data
    to:drawCards(math.min(to.maxHp, 5), this.name)
    if to.dead then return false end
    local x = #to.player_cards[Player.Hand] - math.min(to.maxHp, 5)
    if x > 0 then
      player.room:askToDiscard(to, { min_num = x, max_num = x, include_equip = false, skill_name = this.name, cancelable = false, pattern = ".", prompt = "#ol_ex__jieming-discard:::"..x})
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__jieming"] = "节命",
  [":ol_ex__jieming"] = "当你受到1点伤害后或当你死亡时，你可令一名角色摸X张牌，其将手牌弃置至X张。（X为其体力上限且至多为5）",

  ["#ol_ex__jieming-choose"] = "节命：你可以令一名角色摸X张牌并将手牌弃至X张（X为其体力上限且至多为5）",
  ["#ol_ex__jieming-discard"] = "节命：选择%arg张手牌弃置",

  ["$ol_ex__jieming1"] = "含气在胸，有进无退。",
  ["$ol_ex__jieming2"] = "蕴节于形，生死无惧。",
}

return this