local hongji = fk.CreateSkill{
  name = "hongji",
}

Fk:loadTranslationTable{
  ["hongji"] = "鸿济",
  [":hongji"] = "每轮各限一次，一名角色的准备阶段，若其手牌数为全场最少/最多，你可以令其于本回合摸牌/出牌阶段后额外执行一个摸牌/出牌阶段。",
  --两个条件均满足的话只能选择其中一个发动
  --测不出来鸿济生效的时机（不会和开始时或者结束时自选），只知道跳过此阶段之后不能获得额外阶段
  --暂定摸牌/出牌结束时，获得一个额外摸牌/出牌阶段

  ["#hongji-invoke"] = "鸿济：你可以令 %dest 获得一个额外的阶段",
  ["hongji1"] = "令其获得额外摸牌阶段",
  ["hongji2"] = "令其获得额外出牌阶段",

  ["$hongji1"] = "玄德公当世人杰，奇货可居。",
  ["$hongji2"] = "张某慕君高义，愿鼎力相助。",
}

hongji:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(hongji.name) and target.phase == Player.Start and not target.dead then
      local room = player.room
      if not table.contains(player:getTableMark("hongji-round"), Player.Draw) and
        table.every(room.alive_players, function (p)
          return p:getHandcardNum() >= target:getHandcardNum()
        end) then
        return true
      end
      if not table.contains(player:getTableMark("hongji-round"), Player.Play) and
        table.every(room.alive_players, function (p)
          return p:getHandcardNum() <= target:getHandcardNum()
        end) then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = { "Cancel" }
    if not table.contains(player:getTableMark("hongji-round"), Player.Draw) and
      table.every(room.alive_players, function (p)
        return p:getHandcardNum() >= target:getHandcardNum()
      end) then
      table.insert(choices, "hongji1")
    end
    if not table.contains(player:getTableMark("hongji-round"), Player.Play) and
      table.every(room.alive_players, function (p)
        return p:getHandcardNum() <= target:getHandcardNum()
      end) then
      table.insert(choices, "hongji2")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = hongji.name,
      prompt = "#hongji-invoke::"..target.id,
      all_choices = {"hongji1", "hongji2", "Cancel"},
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:setPlayerMark(target, choice.."-turn", 1)
    if choice == "hongji1" then
      room:addTableMark(player, "hongji-round", Player.Draw)
    else
      room:addTableMark(player, "hongji-round", Player.Play)
    end
  end,
})
hongji:addEffect(fk.EventPhaseEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      ((player.phase == Player.Draw and player:getMark("hongji1-turn") > 0) or
      (player.phase == Player.Play and player:getMark("hongji2-turn") > 0))
  end,
  on_use = function(self, event, target, player, data)
    if player.phase == Player.Draw then
      player.room:setPlayerMark(player, "hongji1-turn", 0)
      player:gainAnExtraPhase(Player.Draw, hongji.name)
    else
      player.room:setPlayerMark(player, "hongji2-turn", 0)
      player:gainAnExtraPhase(Player.Play, hongji.name)
    end
  end,
})

return hongji
