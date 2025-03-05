local ciwei = fk.CreateSkill{
  name = "ciwei",
}

Fk:loadTranslationTable{
  ["ciwei"] = "慈威",
  [":ciwei"] = "其他角色于其回合内使用第二张牌时，若此牌为基本牌或普通锦囊牌，你可弃置一张牌令此牌无效（取消所有目标）。",

  ["#ciwei-invoke"] = "慈威：你可以弃置一张牌，取消 %dest 使用的%arg",

  ["$ciwei1"] = "乃家乃邦，是则是效。",
  ["$ciwei2"] = "其慈有威，不舒不暴。",
}

ciwei:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(ciwei.name) and player.room.current == target and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and not player:isNude() then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local mark = target:getTableMark("ciwei_record-turn")
      if table.contains(mark, use_event.id) then
        return #mark > 1 and mark[2] == use_event.id
      end
      if #mark > 1 then return false end
      mark = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        local use = e.data
        if use.from == target then
          table.insert(mark, e.id)
          return true
        end
      end, Player.HistoryTurn)
      room:setPlayerMark(target, "ciwei_record-turn", mark)
      return #mark > 1 and mark[2] == use_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ciwei.name,
      prompt = "#ciwei-invoke::"..target.id..":"..data.card:toLogString(),
      cancelable = true,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {target}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:removeAllTargets()
    room:throwCard(event:getCostData(self).cards, ciwei.name, player, player)
  end,
})

return ciwei
