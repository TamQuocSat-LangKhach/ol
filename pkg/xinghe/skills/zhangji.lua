local zhangji = fk.CreateSkill{
  name = "zhangjiq",
}

Fk:loadTranslationTable{
  ["zhangjiq"] = "长姬",
  [":zhangjiq"] = "一名角色的结束阶段，若你本回合：造成过伤害，你可以令其摸两张牌；受到过伤害，你可以令其弃置两张牌。",

  ["#zhangjiq-draw"] = "长姬：你可以令 %dest 摸两张牌",
  ["#zhangjiq-discard"] = "长姬：你可以令 %dest 弃置两张牌",

  ["$zhangjiq1"] = "魏武有子数十，唯我最长。",
  ["$zhangjiq2"] = "长姐为大，众弟怎可悖之？",
}

zhangji:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhangji.name) and target.phase == Player.Finish and not target.dead and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == player or (e.data.to == player and not target:isNude())
      end) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    room.logic:getActualDamageEvents(1, function(e)
      if e.data.from == player then
        table.insertIfNeed(choices, "draw")
      end
      if e.data.to == player then
        table.insertIfNeed(choices, "discard")
      end
      return #choices == 2
    end)
    if room:askToSkillInvoke(player, {
      skill_name = zhangji.name,
      prompt = "#zhangjiq-"..choices[1].."::"..target.id,
    }) then
      if #choices == 2 then
        event:setCostData(self, {tos = {target}, choice = choices[1], extra_data = choices[2]})
      else
        event:setCostData(self, {tos = {target}, choice = choices[1]})
      end
      return true
    elseif #choices == 2 and
      room:askToSkillInvoke(player, {
        skill_name = zhangji.name,
        prompt = "#zhangjiq-"..choices[2].."::"..target.id,
      }) then
      event:setCostData(self, {tos = {target}, choice = choices[2]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "draw" then
      target:drawCards(2, zhangji.name)
    elseif choice == "discard" then
      room:askToDiscard(target, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = zhangji.name,
        cancelable = false,
      })
    end
    if event:getCostData(self).extra_data and not player.dead and not target.dead and not target:isNude() and
      room:askToSkillInvoke(player, {
        skill_name = zhangji.name,
        prompt = "#zhangjiq-discard::"..target.id,
      }) then
      room:doIndicate(player, {target})
      room:askToDiscard(target, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = zhangji.name,
        cancelable = false,
      })
    end
  end,
})

return zhangji
