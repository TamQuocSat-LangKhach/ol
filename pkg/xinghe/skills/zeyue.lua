local zeyue = fk.CreateSkill{
  name = "zeyue",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zeyue"] = "迮阅",
  [":zeyue"] = "限定技，准备阶段，你可以令一名你上个回合结束后（首轮为游戏开始后）对你造成过伤害的其他角色失去武将牌上一个技能"..
  "（锁定技、觉醒技、限定技除外）。每轮开始时，其视为对你使用X张【杀】（X为其已失去此技能的轮数），当你受到此【杀】伤害后，其获得以此法失去的技能。",

  ["#zeyue-choose"] = "迮阅：令一名角色失去一个技能，其每轮视为对你使用【杀】，对你造成伤害后恢复失去的技能",
  ["#zeyue-choice"] = "迮阅：选择令 %dest 失去的一个技能",
  ["@zeyue"] = "迮阅",

  ["$zeyue1"] = "以令相迮，束阀阅之家。",
  ["$zeyue2"] = "以正相争，清朝野之妒。",
}

zeyue:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zeyue.name) and player.phase == Player.Start and
      player:usedSkillTimes(zeyue.name, Player.HistoryGame) == 0 then
      local end_id = 1
      player.room.logic:getEventsByRule(GameEvent.Turn, 1, function (e)
        if e.end_id ~= -1 and e.data.who == player then
          end_id = e.end_id
          return true
        end
      end, end_id)
      local optional = {}
      player.room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data
        if damage.to == player and damage.from and not damage.from.dead and damage.from ~= player then
          table.insertIfNeed(optional, damage.from)
        end
      end, nil, end_id)
      if #optional == 0 then return end
      local targets = {}
      for _, p in ipairs(optional) do
        local skills = Fk.generals[p.general]:getSkillNameList(true)
        if p.deputyGeneral ~= "" then
          table.insertTableIfNeed(skills, Fk.generals[p.deputyGeneral]:getSkillNameList(true))
        end
        for _, s in ipairs(skills) do
          if p:hasSkill(s, true) and not Fk.skills[s]:hasTag(Skill.Compulsory) and not Fk.skills[s]:hasTag(Skill.Limited) then
            table.insert(targets, p)
            break
          end
        end
      end
      if #targets > 0 then
        event:setCostData(self, {tos = targets})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = event:getCostData(self).tos,
      skill_name = zeyue.name,
      prompt = "#zeyue-choose",
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
    local choices = {}
    local skills = Fk.generals[to.general]:getSkillNameList(true)
    if to.deputyGeneral ~= "" then
      table.insertTableIfNeed(skills, Fk.generals[to.deputyGeneral]:getSkillNameList(true))
    end
    for _, s in ipairs(skills) do
      if to:hasSkill(s, true) and not Fk.skills[s]:hasTag(Skill.Compulsory) and not Fk.skills[s]:hasTag(Skill.Limited) then
        table.insert(choices, s)
      end
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zeyue.name,
      prompt = "#zeyue-choice::"..to.id,
      detailed = true,
    })
    room:setPlayerMark(player, "@zeyue", choice)
    room:addTableMark(player, "zeyue_record", {to.id, choice, 0})
    room:handleAddLoseSkills(to, "-"..choice)
  end,
})
zeyue:addEffect(fk.RoundStart, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:getMark("zeyue_record") ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("zeyue_record")
    for _, dat in ipairs(mark) do
      for i = 1, dat[3], 1 do
        local from = room:getPlayerById(dat[1])
        if from.dead or player.dead then break end
        local slash = Fk:cloneCard("slash")
        slash.skillName = zeyue.name
        dat[4] = player.id
        local use = {
          from = from,
          tos = {player},
          card = slash,
          extraUse = true,
          extra_data = {
            zeyue_data = dat,
          }
        }
        room:useCard(use)
        dat[4] = use.extra_data.zeyue_data[4]
      end
      if player.dead then return end
    end
    for i = #mark, 1, -1 do
      local dat = mark[i]
      if room:getPlayerById(dat[1]).dead or dat[4] == 0 then
        table.remove(mark, i)
      else
        dat[3] = dat[3] + 1
      end
    end
    if #mark > 0 then
      room:setPlayerMark(player, "zeyue_record", mark)
    else
      room:setPlayerMark(player, "@zeyue", 0)
      room:setPlayerMark(player, "zeyue_record", 0)
    end
  end,
})
zeyue:addEffect(fk.Damaged, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card and table.contains(data.card.skillNames, zeyue.name)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event then
      local use = use_event.data
      local dat = (use.extra_data or {}).zeyue_data
      if dat and dat[4] == player.id then
        room:handleAddLoseSkills(room:getPlayerById(dat[1]), dat[2])
        use.extra_data.zeyue_data[4] = 0
      end
    end
  end,
})

return zeyue
