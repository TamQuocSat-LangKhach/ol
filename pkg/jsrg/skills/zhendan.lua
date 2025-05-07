local zhendan = fk.CreateSkill {
  name = "ol__zhendan",
}

Fk:loadTranslationTable{
  ["ol__zhendan"] = "镇胆",
  [":ol__zhendan"] = "你可以将一张非基本手牌当你本轮未使用过的基本牌使用或打出；当你受到伤害后或每轮结束时，你摸X张牌，然后此技能本轮失效"..
  "（X为本轮所有角色执行过的回合数且至多为5）。",

  ["#ol__zhendan"] = "镇胆：你可以将一张非基本牌当基本牌使用或打出",

  ["$ol__zhendan1"] = "枪出如龙，云心似铁，英雄何惧生死！",
  ["$ol__zhendan2"] = "纵尔等拥十万众来，吾亦不惧半分！",
}

local U = require "packages/utility/utility"

zhendan:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#ol__zhendan",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(zhendan.name, all_names, nil, player:getTableMark("ol__zhendan-round"))
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic and table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = zhendan.name
    return card
  end,
  enabled_at_play = function (self, player)
    return #player:getViewAsCardNames(zhendan.name, Fk:getAllCardNames("b"), nil, player:getTableMark("ol__zhendan-round")) > 0
  end,
  enabled_at_response = function (self, player, response)
    return #player:getViewAsCardNames(zhendan.name, Fk:getAllCardNames("b"), nil, player:getTableMark("ol__zhendan-round")) > 0
  end,
})

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = #room.logic:getEventsOfScope(GameEvent.Turn, 5, Util.TrueFunc, Player.HistoryRound)
    player:drawCards(math.min(num, 5), zhendan.name)
    room:invalidateSkill(player, zhendan.name, "-round")
  end,
}

zhendan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhendan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = spec.on_use,
})

zhendan:addEffect(fk.RoundEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhendan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = spec.on_use,
})

zhendan:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhendan.name, true) and data.card.type == Card.TypeBasic
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "ol__zhendan-round", data.card.trueName)
  end,
})


zhendan:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local names = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player and use.card.type == Card.TypeBasic then
        table.insertIfNeed(names, use.card.trueName)
      end
    end, Player.HistoryRound)
    if #names > 0 then
      room:setPlayerMark(player, "ol__zhendan-round", names)
    end
  end
end)

return zhendan
