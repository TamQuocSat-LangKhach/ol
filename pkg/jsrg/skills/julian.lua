local julian = fk.CreateSkill {
  name = "ol__julian",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["ol__julian"] = "聚敛",
  [":ol__julian"] = "主公技，其他群势力角色每回合限一次，当其于其摸牌阶段外不因此技能而摸牌后，其可以摸一张牌；<br>"..
  "结束阶段，你可以获得所有其他群势力角色各一张手牌。",

  ["#ol__julian-draw"] = "聚敛：你可以摸一张牌",
  ["#ol__julian-invoke"] = "聚敛：你可以获得所有其他群势力角色各一张手牌",

  ["$ol__julian1"] = "",
  ["$ol__julian2"] = "",
}

julian:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(julian.name) then
      for _, move in ipairs(data) do
        if move.to and move.to ~= player and move.to.kingdom == "qun" and move.moveReason == fk.ReasonDraw and
          move.skillName ~= julian.name and move.to.phase ~= Player.Draw and
          move.to:getMark("ol__julian-turn") == 0 and not move.to.dead then
          return true
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local targets = {}
    for _, move in ipairs(data) do
      if move.to and move.to ~= player and move.to.kingdom == "qun" and move.moveReason == fk.ReasonDraw and
        move.skillName ~= julian.name and move.to.phase ~= Player.Draw and
        move.to:getMark("ol__julian-turn") == 0 and not move.to.dead then
        table.insertIfNeed(targets, move.to)
      end
    end
    player.room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not player:hasSkill(julian.name) then return end
      if p:getMark("ol__julian-turn") == 0 and not p.dead then
        event:setCostData(self, {tos = {p}})
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if room:askToSkillInvoke(to, {
      skill_name = julian.name,
      prompt = "#ol__julian-draw",
    }) then
      room:doIndicate(to, {player})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addPlayerMark(to, "ol__julian-turn", 1)
    to:drawCards(1, julian.name)
  end,
})

julian:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(julian.name) and player.phase == Player.Finish and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p.kingdom == "qun" and not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = julian.name,
      prompt = "#ol__julian-invoke",
    }) then
      local tos = table.filter(room:getOtherPlayers(player, false), function(p)
        return p.kingdom == "qun" and not p:isKongcheng()
      end)
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    for _, p in ipairs(tos) do
      if player.dead then return end
      if not p:isKongcheng() and not p.dead then
        local id = room:askToChooseCard(player, {
          target = p,
          flag = "h",
          skill_name = julian.name,
        })
        room:obtainCard(player, id, false, fk.ReasonPrey, player, julian.name)
      end
    end
  end,
})

return julian
