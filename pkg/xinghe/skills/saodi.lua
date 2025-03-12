local saodi = fk.CreateSkill{
  name = "saodi",
}

Fk:loadTranslationTable{
  ["saodi"] = "扫狄",
  [":saodi"] = "当你使用【杀】或普通锦囊牌仅指定一名其他角色为目标时，你可以令你与其之间（计算座次较短的方向）的角色均成为此牌的目标。",

  ["#saodi-invoke"] = "扫狄：你可以令你与 %dest 之间一个方向上所有角色均成为%arg的目标",

  ["$saodi1"] = "狄获悬野，秋风扫之！",
  ["$saodi2"] = "戎狄作乱，岂能坐视！",
}

saodi:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(saodi.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #player.room.alive_players > 3 and
      #data.use.tos == 1 and data.to ~= player then
      local left, right = 0, 0
      if data.to.dead or player:isRemoved() or data.to:isRemoved() then return end
      local temp = player
      while temp ~= data.to do
        if not temp.dead then
          right = right + 1
        end
        temp = temp.next
      end
      left = #Fk:currentRoom().alive_players - right
      if math.min(left, right) > 1 then
        local choice = "both"
        if left > right then
          choice = "anticlockwise"
        elseif left < right then
          choice = "clockwise"
        end
        event:setCostData(self, {choice = choice})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"clockwise", "anticlockwise", "Cancel"}
    local choice = event:getCostData(self).choice
    if choice == "clockwise" then
      table.removeOne(choices, "anticlockwise")
    elseif choice == "anticlockwise" then
      table.removeOne(choices, "clockwise")
    end
    choice = room:askToChoice(player, {
      choices = choices,
      skill_name = saodi.name,
      prompt = "#saodi-invoke::"..data.to.id..":"..data.card:toLogString(),
      all_choices = {"clockwise", "anticlockwise", "Cancel"},
    })
    if choice ~= "Cancel" then
      local tos = {}
      if choice == "clockwise" then
        local temp = data.to.next
        while temp ~= player do
          if not temp.dead then
            table.insert(tos, temp)
          end
          temp = temp.next
        end
      else
        local temp = player.next
        while temp ~= data.to do
          if not temp.dead then
            table.insert(tos, temp)
          end
          temp = temp.next
        end
      end
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(event:getCostData(self).tos, function (p)
      return table.contains(data:getExtraTargets({bypass_distances = true}), p)
    end)
    if #targets > 0 then
      for _, p in ipairs(targets) do
        data:addTarget(p)
      end
    end
  end,
})

return saodi
