local cangzhuo = fk.CreateSkill{
  name = "cangzhuo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["cangzhuo"] = "藏拙",
  [":cangzhuo"] = "锁定技，弃牌阶段开始时，若你于此回合内未使用过锦囊牌，你的锦囊牌于此阶段内不计入手牌上限。",

  ["$cangzhuo1"] = "藏巧于拙，用晦而明。",
  ["$cangzhuo2"] = "寓清于浊，以屈为伸。",
}

cangzhuo:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(cangzhuo.name) and player.phase == Player.Discard then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return end
      return #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == player and use.card.type == Card.TypeTrick
      end, Player.HistoryTurn) == 0
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "cangzhuo-phase", 1)
  end,
})
cangzhuo:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:getMark("cangzhuo-phase") > 0 and card.type == Card.TypeTrick
  end,
})

return cangzhuo
