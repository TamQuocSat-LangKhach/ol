local xiongshu = fk.CreateSkill{
  name = "xiongshu",
}

Fk:loadTranslationTable{
  ["xiongshu"] = "凶竖",
  [":xiongshu"] = "其他角色出牌阶段开始时，你可以弃置X张牌（X为本轮你发动此技能次数，不足则全弃，无牌则不弃），展示其一张手牌，"..
  "你秘密猜测其于此阶段是否会使用与此牌同名的牌。此阶段结束时，若你猜对，你对其造成1点伤害；若你猜错，你获得此牌。",

  ["#xiongshu-invoke"] = "凶竖：你可以展示 %dest 的一张手牌",
  ["#xiongshu-cost"] = "凶竖：你可以弃置%arg张牌，展示 %dest 一张手牌",
  ["#xiongshu-all"] = "凶竖：你可以弃置所有牌，展示 %dest 一张手牌",
  ["#xiongshu-choice"] = "凶竖：猜测 %dest 本阶段是否会使用 %arg",

  ["$xiongshu1"] = "怀志拥权，谁敢不服？",
  ["$xiongshu2"] = "天下凶凶，由我一人。",
}

xiongshu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xiongshu.name) and target.phase == Player.Play and
      not target:isKongcheng() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player:usedSkillTimes(xiongshu.name, Player.HistoryRound)
    local all = table.filter(player:getCardIds("he"), function(id)
      return not player:prohibitDiscard(id)
    end)
    if n == 0 then
      if room:askToSkillInvoke(player, {
        skill_name = xiongshu.name,
        prompt = "#xiongshu-invoke::"..target.id,
      }) then
        event:setCostData(self, {tos = {target}, cards = {}})
        return true
      end
    elseif #all <= n then
      if room:askToSkillInvoke(player, {
        skill_name = xiongshu.name,
        prompt = "#xiongshu-all::"..target.id,
      }) then
        event:setCostData(self, {tos = {target}, cards = all})
        return true
      end
    else
      local cards = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = xiongshu.name,
        prompt = "#xiongshu-cost::"..target.id..":"..n,
        cancelable = true,
        skip = true,
      })
      if #cards > 0 then
        event:setCostData(self, {tos = {target}, cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, xiongshu.name, player, player)
    if player.dead or target.dead or target:isKongcheng() then return end
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = xiongshu.name,
    })
    local name = Fk:getCardById(id).trueName
    target:showCards(id)
    if player.dead or target.dead then return end
    local choice = room:askToChoice(player, {
      choices = {"yes", "no"},
      skill_name = xiongshu.name,
      prompt = "#xiongshu-choice::"..target.id..":"..name,
    })
    room:setPlayerMark(player, "xiongshu-phase", {id, name, choice})
  end,
})
xiongshu:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("xiongshu-phase") ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local id, name, choice = table.unpack(player:getMark("xiongshu-phase"))
    local used = "no"
    if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      return use.from == target and use.card.trueName == name
    end, Player.HistoryPhase) > 0 then
      used = "yes"
    end
    if choice == used then
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = xiongshu.name,
        }
      end
    elseif table.contains(target:getCardIds("hej"), id) or
      table.contains(room.discard_pile, id) or
      table.contains(room.draw_pile, id) then
      room:obtainCard(player, id, true, fk.ReasonPrey, player, xiongshu.name)
    end
  end,
})

return xiongshu
