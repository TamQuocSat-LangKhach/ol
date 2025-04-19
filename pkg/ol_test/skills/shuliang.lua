local shuliang = fk.CreateSkill{
  name = "ol__shuliang",
}

Fk:loadTranslationTable{
  ["ol__shuliang"] = "输粮",
  [":ol__shuliang"] = "每回合限一次，你可以使用或打出一张“粮”。结束阶段，你可以将任意张“粮”分配给其他角色，然后摸X张牌（X为获得“粮”的角色数）。",

  ["#ol__shuliang"] = "输粮：你可以使用或打出一张“粮”",
  ["#ol__shuliang-give"] = "输粮：将任意张“粮”分配给其他角色，然后摸获得“粮”角色数的牌",

  ["$ol__shuliang1"] = "",
  ["$ol__shuliang2"] = "",
}

shuliang:addEffect("viewas", {
  pattern = ".",
  prompt = "#ol__shuliang",
  expand_pile = "ol__lifeng_liang",
  card_filter = function (self, player, to_select, selected)
    if #selected == 0 and table.contains(player:getPile("ol__lifeng_liang"), to_select) then
      local card = Fk:getCardById(to_select)
      if Fk.currentResponsePattern == nil then
        return player:canUse(card) and not player:prohibitUse(card)
      else
        return Exppattern:Parse(Fk.currentResponsePattern):match(card)
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
  enabled_at_play = function (self, player)
    return #player:getPile("ol__lifeng_liang") > 0 and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function (self, player, response)
    if #player:getPile("ol__lifeng_liang") > 0 and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      return table.find(player:getPile("ol__lifeng_liang"), function (id)
        local card = Fk:getCardById(id)
        if Fk.currentResponsePattern == nil then
          return player:canUse(card) and not player:prohibitUse(card)
        else
          return Exppattern:Parse(Fk.currentResponsePattern):match(card)
        end
      end)
    end
  end,
})

shuliang:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shuliang.name) and player.phase == Player.Finish and
      #player:getPile("ol__lifeng_liang") > 0 and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local result = room:askToYiji(player, {
      cards = player:getPile("ol__lifeng_liang"),
      targets = room:getOtherPlayers(player, false),
      skill_name = shuliang.name,
      min_num = 0,
      max_num = 3,
      prompt = "#ol__shuliang-give",
      cancelable = true,
      expand_pile = player:getPile("ol__lifeng_liang"),
      skip = true,
    })
    for _, ids in pairs(result) do
      if #ids > 0 then
        event:setCostData(self, {extra_data = result})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local result = event:getCostData(self).extra_data
    room:doYiji(result, player, shuliang.name)
    if not player.dead then
      local n = 0
      for _, ids in pairs(result) do
        if #ids > 0 then
          n = n + 1
        end
      end
      player:drawCards(n, shuliang.name)
    end
  end,
})

return shuliang
