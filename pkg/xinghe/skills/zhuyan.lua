local zhuyan = fk.CreateSkill{
  name = "zhuyan",
}

Fk:loadTranslationTable{
  ["zhuyan"] = "驻颜",
  [":zhuyan"] = "弃牌阶段结束时，你可以令一名角色将以下项调整至与其上个结束阶段时（若无则改为游戏开始时）相同：体力值；手牌数（至多摸至五张）。"..
  "每名角色每项限一次。",

  ["#zhuyan-choose"] = "驻颜：你可以令一名角色将体力值或手牌数调整至与其上个结束阶段相同",

  ["$zhuyan1"] = "心有灵犀，面如不老之椿。",
  ["$zhuyan2"] = "驻颜有术，此间永得芳容。",
}

zhuyan:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuyan.name) and player.phase == Player.Discard and
      table.find(player.room.alive_players, function (p)
        return not (table.contains(player:getTableMark("zhuyan_hp"), p.id) and
          table.contains(player:getTableMark("zhuyan_handcard"), p.id))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "zhuyan_active",
      prompt = "#zhuyan-choose",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    room:addTableMark(player, choice, to.id)
    if choice == "zhuyan_hp" then
      local n = to:getMark(zhuyan.name)[1] - to.hp
      if n > 0 then
        if to:isWounded() then
          room:recover{
            who = to,
            num = math.min(to:getLostHp(), n),
            recoverBy = player,
            skillName = zhuyan.name,
          }
        end
      elseif n < 0 then
        room:loseHp(to, -n, zhuyan.name)
      end
    else
      local n = to:getMark(zhuyan.name)[2] - to:getHandcardNum()
      if n > 0 then
        to:drawCards(n, zhuyan.name)
      elseif n < 0 then
        room:askToDiscard(to, {
          min_num = -n,
          max_num = -n,
          include_equip = false,
          skill_name = zhuyan.name,
          cancelable = false,
        })
      end
    end
  end,
})
zhuyan:addEffect(fk.GameStart, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, zhuyan.name, {player.hp, math.min(player:getHandcardNum(), 5)})
  end,
})
zhuyan:addEffect(fk.EventPhaseEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, zhuyan.name, {player.hp, math.min(player:getHandcardNum(), 5)})
  end,
})

return zhuyan
