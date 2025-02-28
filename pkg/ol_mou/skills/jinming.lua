local jinming = fk.CreateSkill{
  name = "jinming",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jinming"] = "矜名",
  [":jinming"] = "锁定技，回合开始时，你选择一项条件：1.回复过1点体力；2.弃置过两张牌；3.使用过三种类型的牌；4.造成过4点伤害。"..
  "回合结束时，你摸X张牌，然后若你本回合未满足条件，你删除此选项（X为你上次发动〖矜名〗选择项的序号）。",

  ["#jinming-choice"] = "矜名：选择一项条件，回合结束时摸序号数的牌，若未达到条件则删除选项",
  ["jinming1"] = "[1]回复过1点体力",
  ["jinming2"] = "[2]弃置过两张牌",
  ["jinming3"] = "[3]使用过三张类型的牌",
  ["jinming4"] = "[4]造成过4点伤害",
  ["@jinming"] = "矜名",

  ["$jinming1"] = "士举义或举利，吾，当举大名耳！",
  ["$jinming2"] = "人生百代，我欲垂名于青史。",
}

jinming:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@jinming", 0)
end)

jinming:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jinming.name) and #player:getTableMark(jinming.name) < 4
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {"jinming1", "jinming2", "jinming3", "jinming4"}
    local choices = table.simpleClone(all_choices)
    for _, n in ipairs(player:getTableMark(jinming.name)) do
      table.removeOne(choices, "jinming"..n)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = jinming.name,
      prompt = "#jinming-choice",
      all_choices = all_choices,
    })
    room:setPlayerMark(player, "@jinming", tonumber(choice[8]))
  end,
})
jinming:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jinming.name) and player:getMark("@jinming") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@jinming")
    player:drawCards(n, jinming.name)
    if not table.contains(player:getTableMark(jinming.name), n) then
      local count = 0
      if n == 1 then
        room.logic:getEventsOfScope(GameEvent.Recover, 1, function(e)
          local recover = e.data
          if recover.who == player then
            count = count + recover.num
            return true
          end
        end, Player.HistoryTurn)
      elseif n == 2 then
        room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          for _, move in ipairs(e.data) do
            if move.from == player and move.moveReason == fk.ReasonDiscard then
              count = count + #move.moveInfo
              if count > 1 then
                return true
              end
            end
          end
        end, Player.HistoryTurn)
      elseif n == 3 then
        local types = {}
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data
          if use.from == player then
            table.insertIfNeed(types, use.card.type)
            if #types > 2 then
              return true
            end
          end
        end, Player.HistoryTurn)
        count = #types
      elseif n == 4 then
        player.room.logic:getActualDamageEvents(1, function(e)
          local damage = e.data
          if damage.from == player then
            count = count + damage.damage
            if count > 3 then
              return true
            end
          end
        end)
      end
      if count < n then
        room:addTableMark(player, jinming.name, n)
      end
    end
  end,
})

return jinming
