local fenji = fk.CreateSkill {
  name = "fenji",
}

Fk:loadTranslationTable {
  ["fenji"] = "奋激",
  [":fenji"] = "当一名角色A因另一名角色B的弃置或获得而失去手牌后，你可失去1点体力，令A摸两张牌。",

  ["#fenji-invoke"] = "奋激：你可以失去1点体力，令 %dest 摸两张牌",

  ["$fenji1"] = "百战之身，奋勇趋前！",
  ["$fenji2"] = "两肋插刀，愿赴此去！",
}


---@param player ServerPlayer
---@return boolean
local fenjiTargetFilter = function(player)
  return not player.dead
end

---@param player ServerPlayer
---@param data MoveCardsData[]
---@return ServerPlayer[]
local getFenjiTargets = function(player, data)
  local room = player.room
  local targets = {}
  for _, move in ipairs(data) do
    if not table.contains(targets, move.from) and (move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonPrey) then
      if move.from and move.proposer and move.from ~= move.proposer then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            table.insert(targets, move.from)
            break
          end
        end
      end
    end
  end
  return table.filter(targets, function (p)
    return fenjiTargetFilter(p)
  end)
end

fenji:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  trigger_times = function(self, event, target, player, data)
    local room = player.room
    local fenjiTargets = event:getSkillData(self, "fenji_" .. player.id)
    if fenjiTargets then
      return #table.filter(fenjiTargets.unDone, function (p)
        return fenjiTargetFilter(p)
      end) + (event.invoked_times[self.name] or 0)
    else
      return #getFenjiTargets(player, data)
    end
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fenji.name) and player.hp > 0
  end,
  on_trigger = function(self, event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
    self:doCost(event, target, player, data)
    --用于躲cancel_cost判定
    event:setSkillData(self, "cancel_cost", false)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local fenjiTargets = event:getSkillData(self, "fenji_" .. player.id)
    local to
    if fenjiTargets then
      while #fenjiTargets.unDone > 0 do
        local p = table.remove(fenjiTargets.unDone, 1)
        table.insert(fenjiTargets.done, p)
        if fenjiTargetFilter(p) then
          to = p
          break
        end
      end
    else
      local targets = getFenjiTargets(player, data)
      if #targets > 0 then
        room:sortByAction(targets)
        to = table.remove(targets, 1)
        event:setSkillData(self, "fenji_" .. player.id, { done = { to }, unDone = targets })
      end
    end
    if to and player.room:askToSkillInvoke(player, {
      skill_name = fenji.name,
      prompt = "#fenji-invoke::"..to.id,
    }) then
      event:setCostData(self, {tos = { to }})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:loseHp(player, 1, fenji.name)
    if not to.dead then
      to:drawCards(2, fenji.name)
    end
  end,
})

return fenji
