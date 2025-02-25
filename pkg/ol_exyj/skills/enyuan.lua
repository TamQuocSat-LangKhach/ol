local U =require("packages.utility.utility")

local this = fk.CreateSkill{
  name = "ol_ex__enyuan",
}

this:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(this.name) then return false end
    for _, move in ipairs(data) do
      if move.from and move.from ~= player.id and move.to == player.id and move.toArea == Card.PlayerHand and #move.moveInfo > 1 then
        self.cost_data = move.from
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#ol_ex__enyuan1-invoke::"..data[1]
    if player.room:askToSkillInvoke(player, { skill_name = this.name, prompt = prompt}) then
      self.cost_data = data[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {self.cost_data.id})
    player:broadcastSkillInvoke(this.name, 1)
    room:notifySkillInvoked(player, this.name, "support")
    self.cost_data:drawCards(1, this.name)
  end,
})

this:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(this.name) then return false end
    if target == player and data.from and not data.from.dead and not player.dead then
      self.cost_data = data.from
      return true
    end
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost or player.dead or player.room:getPlayerById(self.cost_data).dead then
        break
      end
      self:doCost(event, target, player, {self.cost_data})
    end
  end,
  on_cost = function (self, event, target, player, data)
    local prompt = "#ol_ex__enyuan2-invoke::"..data[1]
    if player.room:askToSkillInvoke(player, { skill_name = this.name, prompt = prompt}) then
      self.cost_data = data[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = self.cost_data
    room:doIndicate(player.id, {to.id})
    player:broadcastSkillInvoke(this.name, 2)
    room:notifySkillInvoked(player, this.name)
    local card = room:askToCards(to, { min_num = 1, max_num = 1, include_equip = false,
      skill_name = this.name, cancelable = true, pattern = ".|.|heart,diamond|hand|.|.", prompt = "#ol_ex__enyuan-give:"..player.id
    })
    if #card > 0 then
      room:moveCardTo(card, Player.Hand, player, fk.ReasonGive, this.name, nil, false)
    else
      room:loseHp(to, 1, this.name)
    end
  end
})

Fk:loadTranslationTable{
  ["ol_ex__enyuan"] = "恩怨",
  [":ol_ex__enyuan"] = "当你获得一名其他角色至少两张牌后，你可以令其摸一张牌。当你受到1点伤害后，你可以令伤害来源选择一项：1.交给你一张红色手牌；"..
  "2.失去1点体力。",
  
  ["#ol_ex__enyuan1-invoke"] = "恩怨：是否令 %dest 摸一张牌？",
  ["#ol_ex__enyuan2-invoke"] = "恩怨：是否令 %dest 选择交给你牌或失去体力？",
  ["#ol_ex__enyuan-give"] = "恩怨：交给 %src 一张红色手牌，否则你失去1点体力",
  
  ["$ol_ex__enyuan1"] = "恩重如山，必报之以雷霆之势！",
  ["$ol_ex__enyuan2"] = "怨深似海，必还之以烈火之怒！",
}

return this
