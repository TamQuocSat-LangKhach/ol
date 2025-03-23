local jianman = fk.CreateSkill{
  name = "jianman",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jianman"] = "鹣蛮",
  [":jianman"] = "锁定技，每回合结束时，若本回合前两张基本牌的使用者：均为你，你视为使用其中的一张牌；仅其中之一为你，你弃置另一名使用者一张牌。",

  ["#jianman-use"] = "鹣蛮：视为使用其中一张牌",

  ["$jianman1"] = "鹄巡山野，见腐羝而聒鸣！",
  ["$jianman2"] = "我蛮夷也，进退可无矩。",
}

jianman:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jianman.name) then
      local users, names, to = {}, {}, nil
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        local use = e.data
        if use.card.type == Card.TypeBasic then
          table.insert(users, use.from)
          table.insertIfNeed(names, use.card.name)
          return true
        end
      end, Player.HistoryTurn)
      if #users < 2 then return end
      local n = 0
      if users[1] == player then
        n = n + 1
        to = users[2]
      end
      if users[2] == player then
        n = n + 1
        to = users[1]
      end
      local choice = ""
      if n == 2 then
        choice = "use"
        event:setCostData(self, {extra_data = names})
      elseif n == 1 then
        choice = "discard"
        event:setCostData(self, {tos = {to}})
      end
      return choice ~= ""
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).extra_data then
      room:askToUseVirtualCard(player, {
        name = event:getCostData(self).extra_data,
        skill_name = jianman.name,
        prompt = "#jianman-use",
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
        cancelable = false,
      })
    else
      local to = event:getCostData(self).tos[1]
      if not to.dead and not to:isNude() then
        local id = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = jianman.name,
        })
        room:throwCard(id, jianman.name, to, player)
      end
    end
  end,
})

return jianman
