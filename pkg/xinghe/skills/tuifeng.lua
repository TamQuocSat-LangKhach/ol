local tuifeng = fk.CreateSkill{
  name = "tuifeng",
}

Fk:loadTranslationTable{
  ["tuifeng"] = "推锋",
  [":tuifeng"] = "当你受到1点伤害后，你可以将一张牌置于武将牌上，称为“锋”。准备阶段开始时，若你的武将牌上有“锋”，你将所有“锋”置入弃牌堆，"..
  "摸2X张牌，然后你于此回合的出牌阶段内使用【杀】的次数上限+X（X为你此次置入弃牌堆的“锋”数）。",

  ["#tuifeng-ask"] = "推锋：你可以将一张牌置为“锋”",
  ["$tuifeng"] = "推锋",

  ["$tuifeng1"] = "摧锋陷阵，以杀贼首！",
  ["$tuifeng2"] = "敌锋之锐，我已尽知。",
}

tuifeng:addEffect(fk.Damaged, {
  anim_type = "masochism",
  derived_piles = "$tuifeng",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(tuifeng.name) and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = tuifeng.name,
      prompt = "#tuifeng-ask",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player:addToPile("$tuifeng", event:getCostData(self).cards, false, tuifeng.name)
  end,
})
tuifeng:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tuifeng.name) and player.phase == Player.Start and
      #player:getPile("$tuifeng") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #player:getPile("$tuifeng")
    room:moveCardTo(player:getPile("$tuifeng"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, tuifeng.name, nil, true, player)
    if player.dead then return end
    room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn", n)
    player:drawCards(2 * n, tuifeng.name)
  end,
})

return tuifeng
