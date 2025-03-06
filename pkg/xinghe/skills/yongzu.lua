local yongzu = fk.CreateSkill{
  name = "yongzu",
}

Fk:loadTranslationTable{
  ["yongzu"] = "拥族",
  [":yongzu"] = "准备阶段，你可以选择一名其他角色，你与其依次选择不同的一项：<br>1.摸两张牌；<br>2.回复1点体力；<br>3.复原武将牌。<br>"..
  "若选择的角色与你势力相同，则增加选项：<br>4.手牌上限+1；<br>5.根据势力获得技能直到下回合开始：<br>"..
  "<font color='blue'>魏〖奸雄〗</font><font color='grey'>群〖天命〗</font>。",

  ["#yongzu-choose"] = "拥族：你可以选择一名角色，与其依次执行一项（若双方势力相同则增加选项）",
  ["yongzu_skill"] = "获得%arg",
  ["#yongzu-choice"] = "拥族：选择执行的一项",
  ["maxcards1"] = "手牌上限+1",

  ["$yongzu1"] = "既拜我为父，咱家当视汝为骨肉。",
  ["$yongzu2"] = "天地君亲师，此五者最须尊崇。",
}

local function DoYongzu(player, choices, all_choices)
  local room = player.room
  local choice = room:askToChoice(player, {
    choices = choices,
    skill_name = yongzu.name,
    prompt = "#yongzu-choice",
    all_choices = all_choices,
  })
  if choice == "draw2" then
    player:drawCards(2, yongzu.name)
  elseif choice == "recover" then
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = yongzu.name,
    }
  elseif choice == "reset" then
    player:reset()
  elseif choice == "maxcards1" then
    room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
  else
    local skill = string.sub(choice, 16)
    if not player:hasSkill(skill, true) then
      room:addTableMark(player, yongzu.name, skill)
      room:handleAddLoseSkills(player, skill)
    end
  end
  return choice
end

yongzu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yongzu.name) and player.phase == Player.Start and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = yongzu.name,
      prompt = "#yongzu-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local all_choices = {"draw2", "recover", "reset"}
    if player.kingdom == to.kingdom then
      local prompt = "yongzu_skill:::"
      if player.kingdom == "wei" then
        prompt = prompt.."ex__jianxiong"
      elseif player.kingdom == "qun" then
        prompt = prompt.."tianming"
      else
        prompt = prompt.."skill"
      end
      table.insertTable(all_choices, {"maxcards1", prompt})
    end
    local choices = table.simpleClone(all_choices)
    if not player:isWounded() then
      table.remove(choices, 2)
    end
    if #all_choices == 5 and player.kingdom ~= "wei" and player.kingdom ~= "qun" then
      table.remove(choices, -1)
    end
    local choice = DoYongzu(player, choices, all_choices)
    if to.dead then return end
    if choices[2] ~= "recover" and to:isWounded() then
      table.insert(choices, 2, "recover")
    end
    table.removeOne(choices, choice)
    DoYongzu(to, choices, all_choices)
  end,
})
yongzu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(yongzu.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = player:getTableMark(yongzu.name)
    room:setPlayerMark(player, yongzu.name, 0)
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
  end,
})

return yongzu
