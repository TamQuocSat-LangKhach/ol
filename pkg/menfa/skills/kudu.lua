local kudu = fk.CreateSkill{
  name = "kudu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["kudu"] = "苦渡",
  [":kudu"] = "限定技，出牌阶段，你可以重铸两张牌，令一名角色下X个回合结束时摸一张牌，第X个回合后其执行一个额外回合"..
  "（X为你重铸牌点数之差且至多为5）。",

  ["#kudu"] = "苦渡：重铸两张牌，根据点数之差，令一名角色摸牌",
  ["@kudu"] = "苦渡",

  ["$kudu1"] = "",
  ["$kudu2"] = "",
}

kudu:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#kudu",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(kudu.name, Player.HistoryGame) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected < 2
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = math.abs(Fk:getCardById(effect.cards[1]).number - Fk:getCardById(effect.cards[2]).number)
    n = math.min(n, 5)
    room:recastCard(effect.cards, player, kudu.name)
    if n == 0 or target.dead then return end
    room:addTableMark(target, kudu.name, n)
    n = math.max(table.unpack(target:getTableMark(kudu.name)))
    room:setPlayerMark(target, "@kudu", n)
  end
})

kudu:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark(kudu.name) ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n, extra_turn = 0, 0
    local mark = {}
    for _, i in ipairs(player:getTableMark(kudu.name)) do
      n = n + 1
      if i > 1 then
        table.insert(mark, i - 1)
      else
        extra_turn = extra_turn + 1
      end
    end
    room:setPlayerMark(player, kudu.name, #mark > 0 and mark or 0)
    if #mark > 0 then
      room:setPlayerMark(player, "@kudu", math.max(table.unpack(mark)))
    else
      room:setPlayerMark(player, "@kudu", 0)
    end
    player:drawCards(n, kudu.name)
    if not player.dead and extra_turn > 0 then
      for _ = 1, extra_turn do
        player:gainAnExtraTurn(true, kudu.name)
      end
    end
  end,
})

return kudu
