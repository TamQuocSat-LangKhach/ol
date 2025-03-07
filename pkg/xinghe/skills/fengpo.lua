local fengpo = fk.CreateSkill{
  name = "fengpo",
}

Fk:loadTranslationTable{
  ["fengpo"] = "凤魄",
  [":fengpo"] = "当你于回合内首次使用【杀】或【决斗】指定目标后，你可以选择一项：1.摸X张牌；2.此牌伤害+X"..
  "（X为其<font color='red'>♦</font>手牌数）。",

  ["fengpo_draw"] = "摸X张牌",
  ["fengpo_damage"] = "伤害+X",
  ["#fengpo-invoke"] = "凤魄：你可以对 %dest 发动“凤魄”，根据其<font color='red'>♦</font>手牌数执行一项",

  ["$fengpo1"] = "等我提枪上马，打你个落花流水！",
  ["$fengpo2"] = "对付你，用不着我家哥哥亲自上阵！",
}

fengpo:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fengpo.name) and
      (data.card.trueName == "slash" or data.card.trueName == "duel") and
      player.room.current == player and
      not table.contains(player:getTableMark("fengpo-turn"), data.card.trueName) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return end
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == player and use.card.trueName == data.card.trueName
      end, Player.HistoryTurn)
      return use_events[1].id == use_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"fengpo_draw", "fengpo_damage", "Cancel"},
      skill_name = fengpo.name,
      prompt = "#fengpo-invoke::"..data.to.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = #table.filter(data.to:getCardIds("h"), function (id)
      return Fk:getCardById(id).suit == Card.Diamond
    end)
    if n == 0 then return end
    if event:getCostData(self).choice == "fengpo_draw" then
      player:drawCards(n, fengpo.name)
    else
      data.additionalDamage = (data.additionalDamage or 0) + n
    end
  end,
})

return fengpo
