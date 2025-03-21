local hunjiang = fk.CreateSkill{
  name = "hunjiang",
}

Fk:loadTranslationTable{
  ["hunjiang"] = "浑疆",
  [":hunjiang"] = "出牌阶段限一次，你可以令攻击范围内任意名角色同时选择一项：1.令你于本阶段内使用【杀】可以指定其为额外目标；" ..
  "2.令你摸一张牌。若这些角色均选择同一项，则依次执行另一项。",

  ["#hunjiang"] = "浑疆：令任意名角色同时选择：你可以使用【杀】额外指定其为目标，或令你摸牌",
  ["@@hunjiang-phase"] = "浑疆",
  ["hunjiang_extra_target"] = "本阶段 %src 使用【杀】可指定你为额外目标",
  ["hunjiang_draw"] = "令 %dest 摸一张牌",
  ["#hunjiang-choice"] = "浑疆：请选择一项，若你与其他目标均选择同一项，则再执行另一项",
  ["#hunjiang-choose"] = "浑疆：你可以为此【杀】增加“浑疆”角色为额外目标",

  ["$hunjiang1"] = "边野有豪强，敢执干戈动玄黄！",
  ["$hunjiang2"] = "漫天浑雪，弥散八荒。",
}

hunjiang:addEffect("active", {
  anim_type = "offensive",
  prompt = "#hunjiang",
  min_target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(hunjiang.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return player:inMyAttackRange(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.simpleClone(effect.tos)
    room:sortByAction(targets)
    local result = room:askToJointChoice(player, {
      players = targets,
      choices = { "hunjiang_extra_target:"..player.id, "hunjiang_draw::"..player.id },
      skill_name = hunjiang.name,
      prompt = "#hunjiang-choice",
    })
    local firstChosen
    for _, p in ipairs(targets) do
      local choice = result[p]
      if firstChosen == nil then
        firstChosen = choice
      elseif firstChosen ~= choice then
        firstChosen = false
      end
      if choice:startsWith("hunjiang_extra_target") then
        room:addTableMarkIfNeed(p, "@@hunjiang-phase", player.id)
      else
        player:drawCards(1, hunjiang.name)
      end
      if player.dead then return end
    end

    if firstChosen then
      for _, p in ipairs(targets) do
        if firstChosen:startsWith("hunjiang_extra_target") then
          player:drawCards(1, hunjiang.name)
        elseif not p.dead then
          room:addTableMarkIfNeed(p, "@@hunjiang-phase", player.id)
        end
      end
    end
  end,
})
hunjiang:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.card.trueName == "slash" and
      table.find(data:getExtraTargets({bypass_distances = true}), function (p)
        return table.contains(p:getTableMark("@@hunjiang-phase"), player.id)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({bypass_distances = true}), function (p)
      return table.contains(p:getTableMark("@@hunjiang-phase"), player.id)
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 9,
      targets = targets,
      skill_name = hunjiang.name,
      prompt = "#hunjiang-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
  end,
})

return hunjiang
