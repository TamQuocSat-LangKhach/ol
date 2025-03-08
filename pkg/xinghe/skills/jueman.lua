local jueman = fk.CreateSkill{
  name = "jueman",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jueman"] = "蟨蛮",
  [":jueman"] = "锁定技，每回合结束时，若本回合前两张基本牌的使用者：均不为你，你视为使用本回合第三张使用的基本牌；仅其中之一为你，你摸一张牌。",

  ["#jueman-use"] = "蟨蛮：请视为使用【%arg】",

  ["$jueman1"] = "伤人之蛇蝎，向来善藏行。",
  ["$jueman2"] = "我不欲伤人，奈何人自伤。",
}

jueman:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jueman.name) then
      local list = {}
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        if #list == 3 then return true end
        local use = e.data
        if use.card.type == Card.TypeBasic then
          table.insert(list, {use.from, use.card.name})
        end
      end, Player.HistoryTurn)
      if #list < 2 then return false end
      local n = 0
      if list[1][1] == player then
        n = n + 1
      end
      if list[2][1] == player then
        n = n + 1
      end
      local choice = ""
      if #list > 2 and n == 0 then
        choice = list[3][2]
      end
      if n == 1 then
        choice = "draw1"
      end
      if choice ~= "" then
        event:setCostData(self, {choice = choice})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "draw1" then
      player:drawCards(1, jueman.name)
    else
      room:askToUseVirtualCard(player, {
        name = choice,
        skill_name = jueman.name,
        prompt = "#jueman-use:::"..choice,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
        cancelable = false,
      })
    end
  end,
})

return jueman
