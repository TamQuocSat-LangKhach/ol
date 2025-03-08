local wenji = fk.CreateSkill{
  name = "wenji",
}

Fk:loadTranslationTable{
  ["wenji"] = "问计",
  [":wenji"] = "出牌阶段开始时，你可以令一名其他角色交给你一张牌，你于本回合内使用与该牌同名的牌不能被其他角色响应。",

  ["#wenji-choose"] = "问计：你可以令一名其他角色交给你一张牌",
  ["#wenji-give"] = "问计：你需交给 %src 一张牌",
  ["@wenji-turn"] = "问计",

  ["$wenji1"] = "言出子口，入于吾耳，可以言未？",
  ["$wenji2"] = "还望先生救我！",
}

wenji:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wenji.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = wenji.name,
      prompt = "#wenji-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = wenji.name,
      prompt = "#wenji-give:"..player.id,
      cancelable = false,
    })
    room:addTableMarkIfNeed(player, "@wenji-turn", Fk:getCardById(cards[1]).trueName)
    room:obtainCard(player, cards, false, fk.ReasonGive, to, wenji.name)
  end,
})
wenji:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(player:getTableMark("@wenji-turn"), data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
      table.insertIfNeed(data.disresponsiveList, p)
    end
  end,
})

return wenji
