local this = fk.CreateSkill{ name = "ol_ex__jiewei" }

this:addEffect("active", {
  anim_type = "defensive",
  pattern = "nullification",
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("nullification")
    c.skillName = this.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function (self, player)
    return #player.player_cards[Player.Equip] > 0
  end,
})

this:addEffect(fk.TurnedOver, {
  anim_type = "control",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and not player:isNude() and player.faceup
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {min_num = 1, max_num = 1, include_equip = true, skill_name = this.name, cancelable = true, pattern = ".", prompt = "#ol_ex__jiewei-discard", skip = true})
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(this.name)
    room:notifySkillInvoked(player, this.name, "control")
    room:throwCard(self.cost_data, this.name, player, player)
    if player.dead then return false end
    local to = room:askToChooseToMoveCardInBoard(player, { prompt = "#ol_ex__jiewei-choose", skill_name = this.name, cancelable = true})
    if #to == 2 then
      room:askToMoveCardInBoard(player, { target_one = to[1], target_two = to[2], skill_name = this.name})
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__jiewei"] = "解围",
  [":ol_ex__jiewei"] = "①你可将一张装备区里的牌当【无懈可击】使用。②当你翻面后，若你的武将牌正面朝上，你可弃置一张牌，你可将一名角色装备区或判定区里的一张牌置入另一名角色的相同区域。",
  
  ["#ol_ex__jiewei-discard"] = "解围：弃置一张牌发动，之后可以移动场上的一张牌",
  ["#ol_ex__jiewei-choose"] = "解围：你可以移动场上的一张装备牌",

  ["$ol_ex__jiewei1"] = "化守为攻，出奇制胜！",
  ["$ol_ex__jiewei2"] = "坚壁清野，以挫敌锐！",
}

return this