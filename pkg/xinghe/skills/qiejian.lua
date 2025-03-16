local qiejian = fk.CreateSkill{
  name = "qiejian",
}

Fk:loadTranslationTable{
  ["qiejian"] = "切谏",
  [":qiejian"] = "当一名角色失去手牌后，若其没有手牌，你可以与其各摸一张牌，"..
  "然后选择一项：1.弃置你或其场上的一张牌；2.你本轮内不能对其发动此技能。",

  ["#qiejian-invoke"] = "切谏：是否与 %dest 各摸一张牌并选择一项",
  ["#qiejian-choose"] = "切谏：弃置你或 %dest 场上一张牌，或点“取消”本轮不能再对其发动“切谏”",

  ["$qiejian1"] = "东宫不稳，必使众人生异。",
  ["$qiejian2"] = "今三方鼎峙，不宜擅动储君。",
}

---@param player ServerPlayer
---@param target ServerPlayer
---@return boolean
local targetFilter = function(player, target)
  return not (target.dead or table.contains(player:getTableMark("qiejian_prohibit-round"), target.id))
end

---@param player ServerPlayer
---@param data MoveCardsData[]
---@return ServerPlayer[]
local getTargets = function(player, data)
  local room = player.room
  local targets = {}
  for _, move in ipairs(data) do
    if move.from and not table.contains(targets, move.from) and move.from:isKongcheng() then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand then
          table.insert(targets, move.from)
          break
        end
      end
    end
  end
  return table.filter(targets, function (p)
    return targetFilter(player, p)
  end)
end

qiejian:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  trigger_times = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getSkillData(self, self.name .. ":" .. player.id)
    if targets then
      return #table.filter(targets.unDone, function(p)
        return targetFilter(player, p)
      end) + (event.invoked_times[self.name] or 0)
    else
      return #getTargets(player, data)
    end
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qiejian.name)
  end,
  on_trigger = function(self, event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
    self:doCost(event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getSkillData(self, self.name .. ":" .. player.id)
    local to
    if targets then
      while #targets.unDone > 0 do
        local p = table.remove(targets.unDone, 1)
        table.insert(targets.done, p)
        if targetFilter(player, p) then
          to = p
          break
        end
      end
    else
      local targets = getTargets(player, data)
      if #targets > 0 then
        room:sortByAction(targets)
        to = table.remove(targets, 1)
        event:setSkillData(self, self.name .. ":" .. player.id, { done = { to }, unDone = targets })
      end
    end
    if to and player.room:askToSkillInvoke(player, {
      skill_name = qiejian.name,
      prompt = "#qiejian-invoke::"..to.id,
    }) then
      event:setCostData(self, {tos = { to }})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    player:drawCards(1, qiejian.name)
    if not to.dead then
      to:drawCards(1, qiejian.name)
    end
    if player.dead then return end
    local tos = table.filter({player, to}, function (p)
      return #p:getCardIds("ej") > 0
    end)
    if #tos > 0 then
      tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = tos,
        skill_name = qiejian.name,
        prompt = "#qiejian-choose::"..to.id,
        cancelable = true,
      })
    end
    if #tos > 0 then
      local id = room:askToChooseCard(player, {
        target = tos[1],
        flag = "ej",
        skill_name = qiejian.name,
      })
      room:throwCard(id, qiejian.name, to, player)
    else
      room:addTableMarkIfNeed(player, "qiejian_prohibit-round", to.id)
    end
  end,
})

return qiejian
