local xijue = fk.CreateSkill{
  name = "xijue",
}

Fk:loadTranslationTable{
  ["xijue"] = "袭爵",
  [":xijue"] = "游戏开始时，你获得4个“爵”标记；回合结束时，你获得X个“爵”标记（X为你本回合造成的伤害值）。你可以移去1个“爵”标记发动"..
  "〖突袭〗或〖骁果〗。",

  ["@zhanghuyuechen_jue"] = "爵",
  ["#xijue_tuxi-invoke"] = "袭爵：你可以移去1个“爵”标记发动〖突袭〗",
  ["#xijue_xiaoguo-invoke"] = "袭爵：你可以移去1个“爵”标记对 %dest 发动〖骁果〗",

  ["$xijue1"] = "承爵于父，安能辱之！",
  ["$xijue2"] = "虎父安有犬子乎？",
}

xijue:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@zhanghuyuechen_jue", 0)
end)

xijue:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xijue.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@zhanghuyuechen_jue", 4)
  end,
})
xijue:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xijue.name) and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = 0
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data
      if damage.from == player then
        n = n + damage.damage
      end
    end, Player.HistoryTurn)
    room:addPlayerMark(player, "@zhanghuyuechen_jue", n)
  end,
})
xijue:addEffect(fk.DrawNCards, {
  anim_type = "control",
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xijue.name) and data.n > 0 and
      table.find(player.room.alive_players, function(p)
        return p ~= player and not p:isKongcheng()
      end) and
      player:getMark("@zhanghuyuechen_jue") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and not p:isKongcheng()
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = data.n,
      prompt = "#xijue_tuxi-invoke",
      skill_name = "ex__tuxi",
    })
    if #tos > 0 then
      room:removePlayerMark(player, "@zhanghuyuechen_jue", 1)
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ex__tuxi")
    room:notifySkillInvoked(player, "ex__tuxi", "control")
    data.n = data.n - #event:getCostData(self).tos
    for _, p in ipairs(event:getCostData(self).tos) do
      if player.dead then break end
      if not p.dead and not p:isKongcheng() then
        local c = room:askToChooseCard(player, {
          target = p,
          flag = "h",
          skill_name = "ex__tuxi",
        })
        room:obtainCard(player, c, false, fk.ReasonPrey, player, "ex__tuxi")
      end
    end
  end,
})
xijue:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xijue.name) and target.phase == Player.Finish and not target.dead and
      not player:isKongcheng() and player:getMark("@zhanghuyuechen_jue") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = "xiaoguo",
      pattern = ".|.|.|.|.|basic",
      prompt = "#xijue_xiaoguo-invoke::"..target.id,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      room:removePlayerMark(player, "@zhanghuyuechen_jue", 1)
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("xiaoguo")
    room:notifySkillInvoked(player, "xiaoguo", "offensive")
    room:throwCard(event:getCostData(self).cards, "xiaoguo", player, player)
    if target.dead then return false end
    if #room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = "xiaoguo",
      pattern = ".|.|.|.|.|equip",
      prompt = "#xiaoguo-discard:"..player.id,
      cancelable = true,
    }) > 0 then
      if not player.dead then
        player:drawCards(1, "xiaoguo")
      end
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = "xiaoguo",
      }
    end
  end,
})

return xijue
