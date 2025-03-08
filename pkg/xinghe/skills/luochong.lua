local luochong = fk.CreateSkill{
  name = "luochong",
}

Fk:loadTranslationTable{
  ["luochong"] = "落宠",
  [":luochong"] = "准备阶段或当你每回合首次受到伤害后，你可以选择一项，令一名角色：1.回复1点体力；2.失去1点体力；3.弃置两张牌；4.摸两张牌。"..
  "每轮每项限一次，每轮对每名角色限一次。",

  [":luochong_inner"] = "准备阶段或当你每回合首次受到伤害后，你可以选择一项，令一名角色：{1}。"..
  "每轮每项限一次，每轮对每名角色限一次。",

  ["#luochong-invoke"] = "落宠：你可以令一名角色执行一项效果",
  ["luochong1"] = "回复1点体力",
  ["luochong2"] = "失去1点体力",
  ["luochong3"] = "弃置两张牌",
  ["luochong4"] = "摸两张牌",

  ["$luochong1"] = "宠至莫言非，思移难恃貌。",
  ["$luochong2"] = "君王一时情，安有恩长久。",
}

luochong:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "luochong_removed", 0)
  player.room:setPlayerMark(player, "luochong_used-round", 0)
  player.room:setPlayerMark(player, "luochong_targets-round", 0)
end)

local luochong_spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "luochong_active",
      prompt = "#luochong-invoke",
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = tonumber(event:getCostData(self).choice[9])
    room:addTableMark(player, "luochong_targets-round", to.id)
    room:addTableMark(player, "luochong_used-round", choice)
    if choice == 1 then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = luochong.name,
      }
    elseif choice == 2 then
      room:loseHp(to, 1, luochong.name)
    elseif choice == 3 then
      room:askToDiscard(to, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = luochong.name,
        cancelable = false,
      })
    elseif choice == 4 then
      to:drawCards(2, luochong.name)
    end
  end,
}

luochong:addEffect(fk.EventPhaseStart, {
  dynamic_desc = function (self, player)
    if #player:getTableMark("luochong_removed") == 4 then
      return "dummyskill"
    else
      local choices = {}
      for i = 1, 4, 1 do
        if not table.contains(player:getTableMark("luochong_removed"), i) then
          if not table.contains(player:getTableMark("luochong_used-round"), i) then
            table.insert(choices, Fk:translate("luochong"..i))
          else
            table.insert(choices, "<font color=\'gray\'>"..Fk:translate("luochong"..i).."</font>")
          end
        end
      end
      return "luochong_inner:"..table.concat(choices, "；")
    end
  end,
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(luochong.name) and player.phase == Player.Start and
      table.find({1, 2, 3, 4}, function (n)
        return not table.contains(player:getTableMark("luochong_used-round"), n) and
          not table.contains(player:getTableMark("luochong_removed"), n)
      end)
  end,
  on_cost = luochong_spec.on_cost,
  on_use = luochong_spec.on_use,
})
luochong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(luochong.name) and
      table.find({1, 2, 3, 4}, function (n)
        return not table.contains(player:getTableMark("luochong_used-round"), n) and
          not table.contains(player:getTableMark("luochong_removed"), n)
      end) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      local damage_events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == player
      end, Player.HistoryTurn)
      return #damage_events == 1 and damage_events[1].id == player.room.logic:getCurrentEvent().id
    end
  end,
  on_cost = luochong_spec.on_cost,
  on_use = luochong_spec.on_use,
})

return luochong
