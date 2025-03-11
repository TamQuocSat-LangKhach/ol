local quxi = fk.CreateSkill{
  name = "quxi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["quxi"] = "驱徙",
  [":quxi"] = "限定技，出牌阶段结束时，你可以跳过弃牌阶段并翻至背面，选择两名手牌数不同的其他角色，其中手牌少的角色获得另一名角色一张牌"..
  "并获得「丰」，另一名角色获得「歉」。<br>有「丰」的角色摸牌阶段摸牌数+1，有「歉」的角色摸牌阶段摸牌数-1。<br>当有「丰」或「歉」的角色"..
  "死亡时或每轮开始时，你可以转移「丰」「歉」。",

  ["#quxi-invoke"] = "驱徙：选择两名手牌数不同的角色，手牌少的角色获得多的角色一张牌并获得「丰」，手牌多的角色获得「歉」",
  ["@@duxi_feng"] = "丰",
  ["@@duxi_qian"] = "歉",
  ["#quxi1-choose"] = "驱徙：你可以移动 %dest 的「丰」标记（摸牌数+1）",
  ["#quxi2-choose"] = "驱徙：你可以移动 %dest 的「歉」标记（摸牌数-1）",

  ["$quxi1"] = "不自改悔，终须驱徙。",
  ["$quxi2"] = "奈何驱徙，不使存活。",
}

quxi:addLoseEffect(function(self, player)
  local room = player.room
  if player:getMark("quxi_feng_target") ~= 0 then
    local target = room:getPlayerById(player:getMark("quxi_feng_target"))
    room:removePlayerMark(target, "@@duxi_feng", 1)
  end
  if player:getMark("quxi_qian_target") ~= 0 then
    local target = room:getPlayerById(player:getMark("quxi_qian_target"))
    room:removePlayerMark(target, "@@duxi_qian", 1)
  end
end)

quxi:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(quxi.name) and player.phase == Player.Play and
      player:usedEffectTimes(quxi.name, Player.HistoryGame) == 0 and
      (player:getMark("quxi_feng_target") == 0 or player:getMark("quxi_qian_target") == 0) and
      #player.room:getOtherPlayers(player, false) > 1 and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return table.find(player.room:getOtherPlayers(player, false), function (q)
          return p:getHandcardNum() ~= q:getHandcardNum()
        end) ~= nil
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "quxi_active",
      prompt = "#quxi-invoke",
      cancelable = true,
    })
    if success and dat then
      room:sortByAction(dat.targets)
      event:setCostData(self, {tos = dat.targets})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    ---@type ServerPlayer[]
    local targets = event:getCostData(self).tos
    if targets[1]:getHandcardNum() > targets[2]:getHandcardNum() then
      targets = table.reverse(targets)
    end
    player:skip(Player.Discard)
    if player.faceup then
      player:turnOver()
    end
    if targets[1].dead or targets[2].dead then return false end
    if not targets[2]:isKongcheng() then
      local id = room:askToChooseCard(targets[1], {
        target = targets[2],
        flag = "h",
        skill_name = quxi.name,
      })
      room:obtainCard(targets[1], id, false, fk.ReasonPrey, targets[1], quxi.name)
    end
    if player.dead or not player:hasSkill(self, true) then return false end
    if not targets[1].dead then
      room:setPlayerMark(player, "quxi_feng_target", targets[1].id)
      room:addPlayerMark(targets[1], "@@duxi_feng", 1)
    end
    if not targets[2].dead then
      room:setPlayerMark(player, "quxi_qian_target", targets[2].id)
      room:addPlayerMark(targets[2], "@@duxi_qian", 1)
    end
  end,
})
quxi:addEffect(fk.DrawNCards, {
  can_refresh = function (self, event, target, player, data)
    return player:getMark("quxi_feng_target") == target.id or player:getMark("quxi_qian_target") == target.id
  end,
  on_refresh = function (self, event, target, player, data)
    if player:getMark("quxi_feng_target") == target.id then
      data.n = data.n + 1
    end
    if player:getMark("quxi_qian_target") == target.id then
      data.n = data.n - 1
    end
  end,
})
quxi:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(quxi.name) and
      table.find(player.room.alive_players, function(p)
        return player:getMark("quxi_feng_target") == p.id or player:getMark("quxi_qian_target") == p.id
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local target1 = room:getPlayerById(player:getMark("quxi_feng_target"))
    if target1 and not target1.dead then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(target1, false),
        skill_name = quxi.name,
        prompt = "#quxi1-choose::"..target1.id,
        cancelable = true,
      })
      if #to > 0 then
        to = to[1]
        room:setPlayerMark(player, "quxi_feng_target", to.id)
        room:removePlayerMark(target1, "@@duxi_feng", 1)
        room:addPlayerMark(to, "@@duxi_feng", 1)
      end
    end
    target1 = room:getPlayerById(player:getMark("quxi_qian_target"))
    if target1 and not target1.dead then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(target1, false),
        skill_name = quxi.name,
        prompt = "#quxi2-choose::"..target1.id,
        cancelable = true,
      })
      if #to > 0 then
        to = to[1]
        room:setPlayerMark(player, "quxi_qian_target", to.id)
        room:removePlayerMark(target1, "@@duxi_qian", 1)
        room:addPlayerMark(to, "@@duxi_qian", 1)
      end
    end
  end,
})
quxi:addEffect(fk.Death, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(quxi.name) and
      (player:getMark("quxi_feng_target") == target.id or player:getMark("quxi_qian_target") == target.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("quxi_feng_target") == target.id then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(target, false),
        skill_name = quxi.name,
        prompt = "#quxi1-choose::"..target.id,
        cancelable = true,
      })
      if #to > 0 then
        to = to[1]
        room:setPlayerMark(player, "quxi_feng_target", to.id)
        room:removePlayerMark(target, "@@duxi_feng", 1)
        room:addPlayerMark(to, "@@duxi_feng", 1)
      end
    end
    if player:getMark("quxi_qian_target") == target.id then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(target, false),
        skill_name = quxi.name,
        prompt = "#quxi2-choose::"..target.id,
        cancelable = true,
      })
      if #to > 0 then
        to = to[1]
        room:setPlayerMark(player, "quxi_qian_target", to.id)
        room:removePlayerMark(target, "@@duxi_qian", 1)
        room:addPlayerMark(to, "@@duxi_qian", 1)
      end
    end
  end,
})

return quxi
