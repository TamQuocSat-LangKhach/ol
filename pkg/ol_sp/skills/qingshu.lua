local qingshu = fk.CreateSkill{
  name = "qingshu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qingshu"] = "青书",
  [":qingshu"] = "锁定技，游戏开始时，你的准备阶段和结束阶段，你书写一册<a href='tianshu_href'>“天书”</a>。",

  ["tianshu_href"] = "从随机三个时机和三个效果中各选择一个组合为一个“天书”技能。<br>"..
  "“天书”技能初始可使用两次，若交给其他角色则可使用次数改为一次，当次数用完后销毁。<br>"..
  "当一名角色将获得“天书”时，若数量将超过其可拥有“天书”的上限，则选择一个已有“天书”替换。",

  [":tianshu_triggers1"] = "你使用牌后",
  [":tianshu_triggers2"] = "其他角色对你使用牌后",
  [":tianshu_triggers3"] = "出牌阶段开始时",
  [":tianshu_triggers4"] = "你受到伤害后",
  [":tianshu_triggers5"] = "准备阶段",
  [":tianshu_triggers6"] = "结束阶段",
  [":tianshu_triggers7"] = "你造成伤害后",
  [":tianshu_triggers8"] = "你成为【杀】的目标时",
  [":tianshu_triggers9"] = "一名角色进入濒死时",
  [":tianshu_triggers10"] = "你失去装备牌后",
  [":tianshu_triggers11"] = "你使用或打出【闪】时",
  [":tianshu_triggers12"] = "当一张判定牌生效前",
  [":tianshu_triggers13"] = "你失去手牌后",
  [":tianshu_triggers14"] = "你使用的牌被抵消后",
  [":tianshu_triggers15"] = "一名其他角色死亡后",
  [":tianshu_triggers16"] = "当一张判定牌生效后",
  [":tianshu_triggers17"] = "【南蛮入侵】或【万箭齐发】结算后",
  [":tianshu_triggers18"] = "你使用【杀】造成伤害后",
  [":tianshu_triggers19"] = "你于回合外失去红色牌后",
  [":tianshu_triggers20"] = "弃牌阶段开始时",
  [":tianshu_triggers21"] = "一名角色受到【杀】的伤害后",
  [":tianshu_triggers22"] = "摸牌阶段开始时",
  [":tianshu_triggers23"] = "你成为普通锦囊牌的目标后",
  [":tianshu_triggers24"] = "一名角色进入连环状态后",
  [":tianshu_triggers25"] = "一名角色受到属性伤害后",
  [":tianshu_triggers26"] = "一名角色失去最后的手牌后",
  [":tianshu_triggers27"] = "你的体力值变化后",
  [":tianshu_triggers28"] = "每轮开始时",
  [":tianshu_triggers29"] = "一名角色造成伤害时",
  [":tianshu_triggers30"] = "一名角色受到伤害时",

  [":tianshu_effects1"] = "你可以摸一张牌",
  [":tianshu_effects2"] = "你可以弃置一名角色区域内的一张牌",
  [":tianshu_effects3"] = "你可以观看牌堆顶的3张牌，以任意顺序置于牌堆顶或牌堆底",
  [":tianshu_effects4"] = "你可以弃置任意张牌，摸等量张牌",
  [":tianshu_effects5"] = "你可以获得造成伤害的牌",
  [":tianshu_effects6"] = "你可以视为使用一张无距离次数限制的【杀】",
  [":tianshu_effects7"] = "你可以获得一名角色区域内的一张牌",
  [":tianshu_effects8"] = "你可以回复1点体力",
  [":tianshu_effects9"] = "你可以摸3张牌，弃置1张牌",
  [":tianshu_effects10"] = "你可以摸牌至体力上限（至多摸5张）",
  [":tianshu_effects11"] = "你可以令一名角色非锁定技失效直到其下回合开始",
  [":tianshu_effects12"] = "你可以令一名角色摸2张牌并翻面",
  [":tianshu_effects13"] = "你可以令此牌对你无效",
  [":tianshu_effects14"] = "你可以令一名其他角色判定，若结果为♠，你对其造成2点雷电伤害",
  [":tianshu_effects15"] = "你可以用一张手牌替换判定牌",
  [":tianshu_effects16"] = "你可以获得此判定牌",
  [":tianshu_effects17"] = "若你不是体力上限最高的角色，你可以增加1点体力上限",
  [":tianshu_effects18"] = "你可以与一名已受伤角色拼点，若你赢，你获得其两张牌",
  [":tianshu_effects19"] = "你可以令至多两名角色各摸一张牌",
  [":tianshu_effects20"] = "你可以令一名角色的手牌上限+2直到其回合结束",
  [":tianshu_effects21"] = "你可以获得两张非基本牌",
  [":tianshu_effects22"] = "你可以获得两张锦囊牌",
  [":tianshu_effects23"] = "你可以摸3张牌并翻面",
  [":tianshu_effects24"] = "你可以令你对一名角色使用牌无距离次数限制直到你的回合结束",
  [":tianshu_effects25"] = "你可以弃置两张牌，令你和一名其他角色各回复1点体力",
  [":tianshu_effects26"] = "你可以令此伤害值+1",
  [":tianshu_effects27"] = "你可以失去1点体力，摸3张牌",
  [":tianshu_effects28"] = "你可以交换两名角色装备区的牌",
  [":tianshu_effects29"] = "你可以交换两名角色手牌区的牌",
  [":tianshu_effects30"] = "你可以防止此伤害，令伤害来源摸3张牌",

  [":tianshu_inner"] = "（还剩{1}次）{2}，{3}。",
  [":tianshu_unknown"] = "（还剩{1}次）未翻开的天书。",

  ["@[tianshu]"] = "天书",
  ["#tianshu2-discard"] = "弃置 %dest 区域内一张牌",
  ["#tianshu7-prey"] = "获得 %dest 区域内一张牌",
  ["#tianshu18-prey"] = "获得 %dest 两张牌",
  ["@@tianshu11"] = "非锁定技失效",

  ["#qingshu-choice_trigger"] = "请为天书选择一个时机",
  ["#qingshu-choice_effect"] = "请为此时机选择一个效果：<br>%arg，",

  ["#ol__shoushu-discard"] = "“天书”已满，请选择一册删除",

  ["$qingshu1"] = "赤紫青黄，唯记万变其一。",
  ["$qingshu2"] = "天地万法，皆在此书之中。",
  ["$qingshu3"] = "以小篆记大道，则道可道。",
}

Fk:addQmlMark{
  name = "tianshu",
  how_to_show = function(name, value)
    if type(value) == "table" then
      return tostring(#value)
    end
    return " "
  end,
  qml_path = ""
}

local spec = {
  on_use = function (self, event, target, player, data)
    local room = player.room
    --初始化随机数
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))

    --时机
    local nums = {}
    for i = 1, 30, 1 do
      table.insert(nums, i)
    end
    nums = table.random(nums, 3)
    local choices = {
      "tianshu_triggers"..nums[1],
      "tianshu_triggers"..nums[2],
      "tianshu_triggers"..nums[3],
    }
    local choice_trigger = room:askToChoice(player, {
      choices = choices,
      skill_name = qingshu.name,
      prompt = "#qingshu-choice_trigger",
      detailed = true,
    })
    local trigger = tonumber(string.sub(choice_trigger, 17))

    --效果
    nums = {}
    for i = 1, 30, 1 do
      table.insert(nums, i)
    end
    --排除部分绑定时机效果
    if not table.contains({4, 7, 18, 21, 25, 29, 30}, trigger) then
      table.removeOne(nums, 5)  --获得造成伤害的牌
    end
    if not table.contains({8, 23}, trigger) then
      table.removeOne(nums, 13)  --令此牌对你无效
    end
    if not table.contains({12, 16}, trigger) then
      table.removeOne(nums, 15)  --改判
      table.removeOne(nums, 16)  --获得判定牌
    end
    if not table.contains({29, 30}, trigger) then
      table.removeOne(nums, 26)  --伤害+1
      table.removeOne(nums, 30)  --防止伤害
    end
    nums = table.random(nums, 3)
    choices = {
      "tianshu_effects"..nums[1],
      "tianshu_effects"..nums[2],
      "tianshu_effects"..nums[3],
    }
    local choice_effect = room:askToChoice(player, {
      choices = choices,
      skill_name = qingshu.name,
      prompt = "#qingshu-choice_effect:::"..Fk:translate(":"..choice_trigger),
      detailed = true,
    })

    --若将超出上限则舍弃一个已有天书
    if #player:getTableMark("@[tianshu]") > player:getMark("tianshu_max") then
      local skills = table.map(player:getTableMark("@[tianshu]"), function (info)
        return info.skillName
      end)
      local args = {}
      for _, s in ipairs(skills) do
        local info = room:getBanner("tianshu_skills")[s]
        table.insert(args, Fk:translate(":tianshu_triggers"..info[1]).."，"..Fk:translate(":tianshu_effects"..info[2]).."。")
      end
      table.insert(args, "Cancel")
      local choice = room:askToChoice(player, {
        choices = args,
        skill_name = qingshu.name,
        prompt = "#ol__shoushu-discard",
      })
      if choice == "Cancel" then return false end
      local skill = skills[table.indexOf(args, choice)]
      room:handleAddLoseSkills(player, "-"..skill)
      local banner = room:getBanner("tianshu_skills")
      banner[skill] = nil
      room:setBanner("tianshu_skills", banner)
    end

    --房间记录技能信息
    local banner = room:getBanner("tianshu_skills") or {}
    local name = "tianshu"
    for i = 1, 30, 1 do
      if banner["tianshu"..tostring(i)] == nil then
        name = "tianshu"..tostring(i)
        break
      end
    end
    banner[name] = {
      tonumber(string.sub(choice_trigger, 17)),
      tonumber(string.sub(choice_effect, 16)),
      player.id,
    }
    room:setBanner("tianshu_skills", banner)
    room:handleAddLoseSkills(player, name)
  end,
}

qingshu:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(qingshu.name)
  end,
  on_use = spec.on_use,
})

qingshu:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qingshu.name) and
      (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_use = spec.on_use,
})

--以下是一些挂在青书上的天书效果
qingshu:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@tianshu11") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, MarkEnum.UncompulsoryInvalidity, player:getMark("@@tianshu11"))
    room:setPlayerMark(player, "@@tianshu11", 0)
  end,
})

qingshu:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and (player:getMark("tianshu20") > 0 or player:getMark("tianshu24") ~= 0)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("tianshu20") > 0 then
      room:removePlayerMark(player, MarkEnum.AddMaxCards, 2)
      room:removePlayerMark(player, "tianshu20", 2)
    end
    room:setPlayerMark(player, "tianshu24", 0)
  end,
})

qingshu:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(player:getTableMark("tianshu24"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(player:getTableMark("tianshu24"), to.id)
  end,
})

return qingshu
