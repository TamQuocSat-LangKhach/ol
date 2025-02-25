local this = fk.CreateSkill{
  name = "ol_ex__zaiqi",
}

this:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(this.name) and player.phase == Player.Discard then
      local ids = {}
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return false end
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
        return false
      end, turn_event.id)
      local x = #table.filter(ids, function (id)
        return room:getCardArea(id) == Card.DiscardPile and Fk:getCardById(id).color == Card.Red
      end)
      if x > 0 then
        self.cost_data = x
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    local tos = room:askToChoosePlayers(player, { targets = room.alive_players, min_num = 1, max_num = x,
      prompt = "#ol_ex__zaiqi-choose:::"..x, skill_name = this.name, cancelable = true})
    if #tos > 0 then
      room:sortByAction(tos)
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data.tos
    for _, p in ipairs(targets) do
      if not p.dead then
        local choices = {"ol_ex__zaiqi_draw"}
        if player and not player.dead and player:isWounded() then
          table.insert(choices, "ol_ex__zaiqi_recover")
        end
        local choice = room:askToChoice(p, { choices = choices, skill_name = this.name, prompt = "#ol_ex__zaiqi-choice:"..player.id})
        if choice == "ol_ex__zaiqi_draw" then
          p:drawCards(1, this.name)
        else
          room:recover({
            who = player,
            num = 1,
            recoverBy = p,
            skillName = this.name
          })
        end
      end
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__zaiqi"] = "再起",
  [":ol_ex__zaiqi"] = "弃牌阶段结束时，你可选择至多X名角色（X为弃牌堆里于此回合内移至此区域的红色牌数），这些角色各选择：1.令你回复1点体力；2.摸一张牌。",

  ["#ol_ex__zaiqi-choose"] = "再起：选择至多%arg名角色，这些角色各选择令你回复1点体力或摸一张牌",
  ["#ol_ex__zaiqi-choice"] = "再起：选择摸一张牌或令%src回复1点体力",
  ["ol_ex__zaiqi_draw"] = "摸一张牌",
  ["ol_ex__zaiqi_recover"] = "令其回复体力",

  ["$ol_ex__zaiqi1"] = "挫而弥坚，战而弥勇！",
  ["$ol_ex__zaiqi2"] = "蛮人骨硬，其势复来！",
}

return this