local shijian = fk.CreateSkill{
  name = "shijian",
}

Fk:loadTranslationTable{
  ["shijian"] = "实荐",
  [":shijian"] = "一名其他角色于其出牌阶段使用的第二张牌结算结束后，你可以弃置一张牌，令其获得〖誉虚〗直到回合结束。",

  ["#shijian-invoke"] = "实荐：你可以弃置一张牌，令 %dest 获得〖誉虚〗直到回合结束",

  ["$shijian1"] = "国家安危，在于足下。",
  ["$shijian2"] = "行之得道，即社稷用宁。",
}

shijian:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(shijian.name) and target.phase == Player.Play and not player:isNude() and
      not target:hasSkill("yuxu", true) and not target.dead then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        return e.data.from == target
      end, Player.HistoryPhase)
      return #events == 2 and events[2].data == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = shijian.name,
      prompt = "#shijian-invoke::"..target.id,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, shijian.name, player, player)
    if target.dead then return end
    room:handleAddLoseSkills(target, "yuxu")
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(target, "-yuxu")
    end)
  end,
})

return shijian
