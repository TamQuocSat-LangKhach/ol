local xiayong = fk.CreateSkill{
  name = "xiayong",
}

Fk:loadTranslationTable{
  ["xiayong"] = "狭勇",
  [":xiayong"] = "出牌阶段限一次，你可以选择一名其他角色，直到其下个回合结束：你处于【酒】的状态；其对除其以外的角色使用牌后，你可以对其使用"..
  "一张无视防具的【杀】。",

  ["#xiayong"] = "狭勇：选择一名角色，直到其回合结束，你始终处于“酒”状态且当其使用牌后可以对其使用【杀】",
  ["#xiayong-invoke"] = "狭勇：是否对 %dest 使用一张无视防具的【杀】？",
}

xiayong:addEffect("active", {
  anim_type = "offensive",
  prompt = "#xiayong",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xiayong.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, xiayong.name, target.id)
    if player.drank == 0 then
      player.drank = 1
      room:broadcastProperty(player, "drank")
    end
  end,
})
xiayong:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.contains(player:getTableMark("xiayong"), target.id) and not target.dead and
      table.find(data.tos or {}, function (p)
        return p ~= target
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseCard(player, {
      skill_name = "xiayong",
      pattern = "slash",
      prompt = "#xiayong-invoke::"..target.id,
      cancelable = true,
      extra_data = {
        must_targets = {target.id},
        bypass_distances = true,
      },
    })
    if use then
      use.extraUse = true
      use.extra_data = use.extra_data or {}
      use.extra_data.xiayongUser = player.id
      room:useCard(use)
    end
  end,
})
xiayong:addEffect(fk.TargetSpecified, {
  can_refresh = function (self, event, target, player, data)
    return target == player and (data.extra_data or {}).xiayongUser == player.id and not data.to.dead
  end,
  on_refresh = function (self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})
xiayong:addEffect(fk.AfterTurnEnd, {
  can_refresh = function (self, event, target, player, data)
    return table.contains(player:getTableMark(xiayong.name), target.id)
  end,
  on_refresh = function (self, event, target, player, data)
    local mark = player:getTableMark(xiayong.name)
    for i = #mark, 1, -1 do
      if mark[i] == target.id then
        table.remove(mark, i)
      end
    end
    if #mark == 0 then
      player.room:setPlayerMark(player, xiayong.name, 0)
    else
      player.room:setPlayerMark(player, xiayong.name, mark)
    end
  end,
})
xiayong:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("xiayong") ~= 0 and player.drank == 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.drank = 1
    player.room:broadcastProperty(player, "drank")
  end,
})
xiayong:addEffect(fk.EventTurnChanging, {
  can_refresh = function (self, event, target, player, data)
    return player:getMark("xiayong") ~= 0 and player.drank == 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.drank = 1
    player.room:broadcastProperty(player, "drank")
  end,
})

return xiayong
