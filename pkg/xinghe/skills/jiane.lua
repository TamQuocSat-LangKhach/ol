local jiane = fk.CreateSkill{
  name = "jiane",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiane"] = "謇谔",
  [":jiane"] = "锁定技，当你对其他角色使用的牌生效后，其本回合不能抵消牌；当你抵消牌后，你本回合不能成为牌的目标。",

  ["@@jiane_buff-turn"] = "謇谔",
  ["@@jiane_debuff-turn"] = "謇谔",

  ["$jiane1"] = "臣者，未死于战，则死于谏。",
  ["$jiane2"] = "君有弊，坐视之辈甚于外贼。",
}

jiane:addEffect(fk.CardEffecting, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jiane.name) and data.from == player and
      table.find(data.tos, function (p)
        return p ~= player and p:getMark("@@jiane_debuff-turn") == 0 and not p.dead
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local tos2 = {}
    for _, p in ipairs(data.tos) do
      if p ~= player and p:getMark("@@jiane_debuff-turn") == 0 and not p.dead then
        room:setPlayerMark(p, "@@jiane_debuff-turn", 1)
        table.insert(tos2, p)
      end
    end
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      e.data.unoffsetableList = e.data.unoffsetableList or {}
      table.insertTableIfNeed(e.data.unoffsetableList, tos2)
    end, nil, Player.HistoryTurn)
  end,
})
jiane:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jiane.name) and player:getMark("@@jiane_buff-turn") == 0 then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return end
      local is_from = false
      player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.responseToEvent == data then
          if use.from == player then
            is_from = true
          end
          return true
        end
      end, use_event.id)
      return is_from
    end
  end,
})
jiane:addEffect(fk.PreCardUse, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    data.unoffsetableList = data.unoffsetableList or {}
    for _, p in ipairs(player.room.alive_players) do
      if p:getMark("@@jiane_debuff-turn") > 0 then
        table.insert(data.unoffsetableList, p)
      end
    end
  end,
})
jiane:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return to:getMark("@@jiane_buff-turn") > 0
  end,
})

return jiane
