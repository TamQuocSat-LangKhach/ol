local enyuan = fk.CreateSkill{
  name = "ol_ex__enyuan",
}

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

enyuan:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(enyuan.name) then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player and move.to == player and move.toArea == Card.PlayerHand and #move.moveInfo > 1 then
          return true
        end
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      if move.from and move.from ~= player and move.to == player and move.toArea == Card.PlayerHand and #move.moveInfo > 1 then
        table.insertIfNeed(targets, move.from)
      end
    end
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not player:hasSkill(enyuan.name) then return end
      if not p.dead then
        event:setCostData(self, {tos = {target}})
        self:doCost(event, p, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = enyuan.name,
      prompt = "#ol_ex__enyuan1-invoke::"..event:getCostData(self).tos[1].id,
    }) then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(enyuan.name, 1)
    room:notifySkillInvoked(player, enyuan.name, "support")
    event:getCostData(self).tos[1]:drawCards(1, enyuan.name)
  end,
})

enyuan:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(enyuan.name) and data.from and not data.from.dead
  end,
  on_trigger = function(self, event, target, player, data)
    for i = 1, data.damage do
      if event:isCancelCost(self) or player.dead or data.from.dead then
        break
      end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = enyuan.name,
      prompt = "#ol_ex__enyuan2-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(enyuan.name, 2)
    room:notifySkillInvoked(player, enyuan.name, "masochism")
    local card = room:askToCards(data.from, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = enyuan.name,
      cancelable = true,
      pattern = ".|.|heart,diamond|hand|.|.",
      prompt = "#ol_ex__enyuan-give:"..player.id,
    })
    if #card > 0 then
      room:moveCardTo(card, Player.Hand, player, fk.ReasonGive, enyuan.name, nil, false, data.from)
    else
      room:loseHp(data.from, 1, enyuan.name)
    end
  end
})

return enyuan
