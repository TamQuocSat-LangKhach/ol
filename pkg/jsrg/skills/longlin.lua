local longlin = fk.CreateSkill {
  name = "ol__longlin",
}

Fk:loadTranslationTable{
  ["ol__longlin"] = "龙临",
  [":ol__longlin"] = "当其他角色于其出牌阶段内首次使用【杀】指定目标后，你可以弃置一张牌令此【杀】无效，然后其可以视为对你使用一张【决斗】，"..
  "你以此法造成伤害后，其本阶段使用的下一张牌不能指定除其以外的角色为目标。",

  ["#ol__longlin-invoke"] = "龙临：弃置一张牌，令 %dest 使用的%arg无效，然后其可以视为对你使用【决斗】 ",
  ["#ol__longlin-duel"] = "龙临：是否视为对 %dest 使用【决斗】？",
  ["@@ol__longlin-phase"] = "龙临",

  ["$ol__longlin1"] = "克祸定乱、义贯金石，云在此，复何伤？",
  ["$ol__longlin2"] = "龙战于野，吐息四海九州，万物将生！",
}

longlin:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(longlin.name) and target ~= player and target.phase == Player.Play and
      data.card.trueName == "slash" and data.firstTarget and not player:isNude() then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.card.trueName == "slash" and use.from == target
      end, Player.HistoryPhase)
      return #use_events == 1 and use_events[1].id == player.room.logic:getCurrentEvent().id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = longlin.name,
      cancelable = true,
      prompt = "#ol__longlin-invoke::"..target.id..":"..data.card:toLogString(),
      skip = true
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, longlin.name, player, player)
    data.use.nullifiedTargets = table.simpleClone(room.players)
    if player.dead or target.dead then return end
    if not target:isProhibited(player, Fk:cloneCard("duel")) and
      room:askToSkillInvoke(target, {
        skill_name = longlin.name,
        prompt = "#ol__longlin-duel::"..player.id,
      }) then
      room:useVirtualCard("duel", nil, target, player, longlin.name, true)
    end
  end,
})

longlin:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    if target == player and data.card and data.card.trueName == "duel" and
      table.contains(data.card.skillNames, longlin.name) and not data.to.dead then
      local e = player.room.logic:getCurrentEvent().parent
      while e do
        if e.event == GameEvent.SkillEffect then
          local dat = e.data
          if dat.skill.name == longlin.name and dat.who == player then
            return true
          end
        end
        e = e.parent
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(data.to, "@@ol__longlin-phase", 1)
  end,
})

longlin:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@ol__longlin-phase") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ol__longlin-phase", 0)
  end,
})

longlin:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return from:getMark("@@ol__longlin-phase") > 0 and card and to ~= from
  end,
})

return longlin
