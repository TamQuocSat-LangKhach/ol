local shanduan = fk.CreateSkill{
  name = "shanduan",
  tags = { Skill.Compulsory },
  dynamic_desc = function (self, player, lang)
    local nums = player:getTableMark(shanduan.name)
    for i = 1, 4, 1 do
      if player:getMark("shanduan"..i.."-turn") > 0 then
        table.insert(nums, player:getMark("shanduan"..i.."-turn"))
      end
    end
    table.sort(nums)
    return "shanduan_inner:"..nums[1]..":"..nums[2]..":"..nums[3]..":"..nums[4]
  end,
}

Fk:loadTranslationTable{
  ["shanduan"] = "善断",
  [":shanduan"] = "锁定技，你的阶段开始时，将数值1、2、3、4分配给以下项：<br>"..
  "摸牌阶段开始时，你选择本回合摸牌阶段摸牌数；<br>出牌阶段开始时，你选择本回合攻击范围、出牌阶段使用【杀】次数上限；<br>"..
  "弃牌阶段开始时，你选择本回合手牌上限。<br>当你于回合外受到伤害后，你下回合分配数值中的最小值+1。",

  [":shanduan_inner"] = "锁定技，你的阶段开始时，将数值{1}、{2}、{3}、{4}分配给以下项：<br>"..
  "摸牌阶段开始时，你选择本回合摸牌阶段摸牌数；<br>出牌阶段开始时，你选择本回合攻击范围、出牌阶段使用【杀】次数上限；<br>"..
  "弃牌阶段开始时，你选择本回合手牌上限。<br>当你于回合外受到伤害后，你下回合分配数值中的最小值+1。",

  ["#shanduan-choice"] = "善断：选择本回合%arg的数值",
  ["shanduan_ch1"] = "摸牌阶段摸牌数",
  ["shanduan_ch2"] = "攻击范围",
  ["shanduan_ch3"] = "手牌上限",
  ["shanduan_ch4"] = "【杀】次数上限",
  ["#shanduanDistribution"] = "%from 令 %arg 为 %arg2",

  ["$shanduan1"] = "浪子回头，其期未晚矣！",
  ["$shanduan2"] = "心既存蛟虎，秉慧剑斩之！",
}

shanduan:addAcquireEffect(function (self, player, is_start)
  player.room:setPlayerMark(player, shanduan.name, {1, 2, 3, 4})
end)

shanduan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, shanduan.name, 0)
end)

shanduan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanduan.name) and
      player.phase >= Player.Draw and player.phase <= Player.Discard and
      #player:getTableMark(shanduan.name) > 0 and
      player:getMark("shanduan"..(player.phase - 3).."-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = player:getTableMark(shanduan.name)
    local choices = table.map(nums, function (i)
      return tostring(i)
    end)
    if #choices == 0 then return end
    local value = "shanduan_ch"..(player.phase - 3)
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = shanduan.name,
      prompt = "#shanduan-choice:::"..value,
    })
    room:setPlayerMark(player, "shanduan"..(player.phase - 3).."-turn", tonumber(choice))
    table.removeOne(nums, tonumber(choice))
    room:setPlayerMark(player, shanduan.name, nums)
    table.removeOne(choices, choice)
    room:sendLog{
      type = "#shanduanDistribution",
      from = player.id,
      arg = value,
      arg2 = choice,
    }
    if player.phase == Player.Play then
      choice = room:askToChoice(player, {
        choices = choices,
        skill_name = shanduan.name,
        prompt = "#shanduan-choice:::shanduan_ch4",
      })
      room:setPlayerMark(player, "shanduan4-turn", tonumber(choice))
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn", tonumber(choice) - 1)
      table.removeOne(nums, tonumber(choice))
      room:setPlayerMark(player, shanduan.name, nums)
      room:sendLog{
        type = "#shanduanDistribution",
        from = player.id,
        arg = "shanduan_ch4",
        arg2 = choice,
      }
    end
  end,
})
shanduan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanduan.name) and player.room.current ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = player:getTableMark(shanduan.name)
    if #nums ~= 4 then
      nums = {2, 2, 3, 4}
    else
      local k = 1
      for i = 2, 4, 1 do
        if nums[i] < nums[k] then
          k = i
        end
      end
      nums[k] = nums[k] + 1
    end
    room:setPlayerMark(player, shanduan.name, nums)
  end,
})
shanduan:addEffect(fk.DrawNCards, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("shanduan1-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.n = data.n + player:getMark("shanduan1-turn") - 2
  end,
})
shanduan:addEffect("atkrange", {
  fixed_func = function (self, from)
    if from:getMark("shanduan2-turn") > 0 then
      return from:getMark("shanduan2-turn")
    end
  end,
})
shanduan:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:getMark("shanduan3-turn") > 0 then
      return player:getMark("shanduan3-turn")
    end
  end,
})
shanduan:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanduan.name, true) and #player:getTableMark(shanduan.name) ~= 4
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, shanduan.name, {1, 2, 3, 4})
  end,
})
shanduan:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanduan.name, true) and #player:getTableMark(shanduan.name) ~= 4
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, shanduan.name, {1, 2, 3, 4})
  end,
})

return shanduan
