local tongxie = fk.CreateSkill{
  name = "tongxie",
}

Fk:loadTranslationTable{
  ["tongxie"] = "同协",
  [":tongxie"] = "出牌阶段开始时，你可以令你与至多两名其他角色直到你的下回合开始成为“同协”角色，然后令其中手牌唯一最少的角色摸一张牌。<br>"..
  "当同协角色不以此法使用的仅指定唯一目标的【杀】结算后，其他同协角色可以依次对目标使用一张无距离限制的【杀】。<br>"..
  "当同协角色受到伤害时，本回合未失去过体力的其他同协角色可以防止此伤害并失去1点体力。",

  ["#tongxie-choose"] = "同协：选择至多两名其他角色与你成为“同协”角色",
  ["@@tongxie"] = "同协",
  ["#tongxie-slash"] = "同协：你可以对 %dest 使用一张【杀】（无距离限制）",
  ["#tongxie-loseHp"] = "同协：%dest 受到伤害，你可以失去1点体力防止之",

  ["$tongxie1"] = "分则必败，合则可胜！",
  ["$tongxie2"] = "唯同心协力，方可破敌。",
}

tongxie:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongxie.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "choose_players_skill",
      prompt = "#tongxie-choose",
      skip = true,
      extra_data = {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        num = 2,
        min_num = 0,
        pattern = "",
        skillName = tongxie.name,
      },
    })
    if success and dat then
      table.insert(dat.targets, player)
      room:sortByAction(dat.targets)
      event:setCostData(self, {tos = dat.targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    room:setPlayerMark(player, "tongxie_src", table.map(targets, Util.IdMapper))
    local nums = {}
    for _, p in ipairs(targets) do
      local mark = p:getTableMark("@@tongxie")
      mark[tostring(player.id)] = table.map(targets, Util.IdMapper)
      room:setPlayerMark(p, "@@tongxie", mark)
      table.insert(nums, p:getHandcardNum())
    end
    local to = table.filter(targets, function (p)
      return table.every(targets, function (q)
        return p:getHandcardNum() <= q:getHandcardNum()
      end)
    end)
    if #to == 1 then
      to[1]:drawCards(1, tongxie.name)
    end
  end,
})

tongxie:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if data.card.trueName == "slash" and player:getMark("@@tongxie") ~= 0 and
      target ~= player and not player.dead and
      data:isOnlyTarget(data.tos[1]) and data.tos[1] ~= player then
      for _, value in pairs(player:getMark("@@tongxie")) do
        if not (data.extra_data and data.extra_data.tongxie) and
          table.contains(value, target.id) then
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseCard(player, {
      skill_name = tongxie.name,
      pattern = "slash",
      prompt = "#tongxie-slash::"..data.tos[1].id,
      extra_data = {
        exclusive_targets = {data.tos[1].id},
        bypass_distances = true,
        bypass_times = true,
      }
    })
    if use then
      player:broadcastSkillInvoke(tongxie.name)
      room:notifySkillInvoked(player, tongxie.name, "offensive")
      use.extraUse = true
      use.extra_data = use.extra_data or {}
      use.extra_data.tongxie = true
      room:useCard(use)
    end
  end,
})
tongxie:addEffect(fk.DamageInflicted, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if player:getMark("@@tongxie") ~= 0 and target ~= player and not player.dead and
      #player.room.logic:getEventsOfScope(GameEvent.LoseHp, 1, function (e)
        return e.data.who == player
      end, Player.HistoryTurn) == 0 then
      for _, value in pairs(player:getMark("@@tongxie")) do
        if table.contains(value, target.id) then
          return true
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = tongxie.name,
      prompt = "#tongxie-loseHp::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
    player.room:loseHp(player, 1, tongxie.name)
  end,
})

local tongxie_clear_spec = {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("tongxie_src") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local tos = player:getMark("tongxie_src")
    room:setPlayerMark(player, "tongxie_src", 0)
    for _, id in ipairs(tos) do
      local p = room:getPlayerById(id)
      if not p.dead and p:getMark("@@tongxie") ~= 0 then
        local mark = p:getMark("@@tongxie")
        mark[tostring(player.id)] = nil
        if next(mark) == nil then
          room:setPlayerMark(p, "@@tongxie", 0)
        else
          room:setPlayerMark(p, "@@tongxie", mark)
        end
      end
    end
  end,
}

tongxie:addEffect(fk.TurnStart, tongxie_clear_spec)
tongxie:addEffect(fk.Death, tongxie_clear_spec)

return tongxie
