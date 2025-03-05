local caiyuan = fk.CreateSkill{
  name = "caiyuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["caiyuan"] = "才媛",
  [":caiyuan"] = "锁定技，回合结束时，若你于上回合结束至今未扣减过体力，你摸两张牌。",

  ["$caiyuan1"] = "柳絮轻舞，撷芳赋诗。",
  ["$caiyuan2"] = "秀媛才德，知书达理。",
}

caiyuan:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(caiyuan.name) then
      local end_id = player:getMark("caiyuan_record-turn")
      if end_id < 0 then return false end
      local room = player.room
      if end_id == 0 then
        local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
        if turn_event == nil then return false end
        room.logic:getEventsByRule(GameEvent.Turn, 1, function(e)
          if e.data.who == player and e.id ~= turn_event.id then
            end_id = e.id
            return true
          end
        end, end_id)
      end
      if end_id == 0 then
        room:setPlayerMark(player, "caiyuan_record-turn", -1)
        return false
      end
      room.logic:getEventsByRule(GameEvent.ChangeHp, 1, function(e)
        if e.data.who == player and e.data.num < 0 then
          end_id = -1
          room:setPlayerMark(player, "caiyuan_record-turn", -1)
          return true
        end
      end, end_id)
      if end_id > 0 then
        room:setPlayerMark(player, "caiyuan_record-turn", room.logic.current_event_id)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, caiyuan.name)
  end,
})

return caiyuan
