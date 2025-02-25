local this = fk.CreateSkill{
  name = "cangzhuo",
}

this:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(this.name) and player.phase == Player.Discard then
      local room = player.room
      local logic = room.logic
      local e = logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if e == nil then return false end
      local end_id = e.id
      local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      for i = #events, 1, -1 do
        e = events[i]
        if e.id <= end_id then break end
        local use = e.data[1]
        if use.from == player.id and use.card.type == Card.TypeTrick then
          return false
        end
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "cangzhuo-phase")
  end,
})

this:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return player:getMark("cangzhuo-phase") > 0 and card.type == Card.TypeTrick
  end,
})

Fk:loadTranslationTable {
  ["cangzhuo"] = "藏拙",
  [":cangzhuo"] = "锁定技，弃牌阶段开始时，若你于此回合内未使用过锦囊牌，你的锦囊牌于此阶段内不计入手牌上限。",

  ["$cangzhuo1"] = "藏巧于拙，用晦而明。",
  ["$cangzhuo2"] = "寓清于浊，以屈为伸。",
}

return this
