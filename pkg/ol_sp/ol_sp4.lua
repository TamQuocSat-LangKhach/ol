
local nanhualaoxian = General(extension, "ol__nanhualaoxian", "qun", 3)
local ol__shoushu = fk.CreateActiveSkill{
  name = "ol__shoushu",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#ol__shoushu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      table.find(player:getTableMark("@[tianshu]"), function (info)
        return player:usedSkillTimes(info.skillName, Player.HistoryGame) == 0
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local skills = table.filter(player:getTableMark("@[tianshu]"), function (info)
      return player:usedSkillTimes(info.skillName, Player.HistoryGame) == 0
    end)
    skills = table.map(skills, function (info)
      return info.skillName
    end)
    local args = {}
    for _, s in ipairs(skills) do
      local info = room:getBanner("tianshu_skills")[s]
      table.insert(args, Fk:translate(":tianshu_triggers"..info[1]).."，"..Fk:translate(":tianshu_effects"..info[2]).."。")
    end
    local choice = room:askForChoice(player, args, self.name, "#ol__shoushu-give::"..target.id)
    local skill = skills[table.indexOf(args, choice)]
    if #target:getTableMark("@[tianshu]") > target:getMark("tianshu_max") then
      skills = table.map(target:getTableMark("@[tianshu]"), function (info)
        return info.skillName
      end)
      local to_throw = skills[1]
      if #skills > 1 then
        args = {}
        for _, s in ipairs(skills) do
          local info = room:getBanner("tianshu_skills")[s]
          table.insert(args, Fk:translate(":tianshu_triggers"..info[1]).."，"..Fk:translate(":tianshu_effects"..info[2]).."。")
        end
        choice = room:askForChoice(target, args, self.name, "#ol__shoushu-discard")
        to_throw = skills[table.indexOf(args, choice)]
      end
      room:handleAddLoseSkills(target, "-"..to_throw, nil, true, false)
      local banner = room:getBanner("tianshu_skills")
      banner[to_throw] = nil
      room:setBanner("tianshu_skills", banner)
    end
    room:handleAddLoseSkills(player, "-"..skill, nil, true, false)
    room:handleAddLoseSkills(target, skill, nil, true, false)
  end,
}
local qingshu = fk.CreateTriggerSkill{
  name = "qingshu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventPhaseStart then
        return target == player and (player.phase == Player.Start or player.phase == Player.Finish)
      end
    end
  end,
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
    local choice_trigger = room:askForChoice(player, choices, self.name, "#qingshu-choice_trigger", true)
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
    local choice_effect = room:askForChoice(player, choices, self.name,
      "#qingshu-choice_effect:::"..Fk:translate(":"..choice_trigger), true)

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
      local choice = room:askForChoice(player, args, self.name, "#ol__shoushu-discard")
      if choice == "Cancel" then return false end
      local skill = skills[table.indexOf(args, choice)]
      room:handleAddLoseSkills(player, "-"..skill, nil, true, false)
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
      player.id
    }
    room:setBanner("tianshu_skills", banner)
    room:handleAddLoseSkills(player, name, nil, true, false)
  end,

  --几个持续一段时间的标记效果
  refresh_events = {fk.TurnStart, fk.AfterTurnEnd},
  can_refresh = function (self, event, target, player, data)
    if target == player then
      if event == fk.TurnStart then
        return player:getMark("@@tianshu11") > 0
      elseif event == fk.AfterTurnEnd then
        return player:getMark("tianshu20") > 0 or player:getMark("tianshu24") ~= 0
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:removePlayerMark(player, MarkEnum.UncompulsoryInvalidity, player:getMark("@@tianshu11"))
      room:setPlayerMark(player, "@@tianshu11", 0)
    elseif event == fk.AfterTurnEnd then
      if player:getMark("tianshu20") > 0 then
        room:removePlayerMark(player, MarkEnum.AddMaxCards, 2)
        room:removePlayerMark(player, "tianshu20", 2)
      end
      room:setPlayerMark(player, "tianshu24", 0)
    end
  end,
}
local tianshu_targetmod = fk.CreateTargetModSkill{  --姑且挂在青书上……
  name = "#tianshu_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(player:getTableMark("tianshu24"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(player:getTableMark("tianshu24"), to.id)
  end,
}
qingshu:addRelatedSkill(tianshu_targetmod)
for loop = 1, 30, 1 do  --30个肯定够用
  local tianshu = fk.CreateTriggerSkill{
    name = "tianshu"..loop,
    anim_type = "special",
    events = {fk.CardUseFinished, fk.EventPhaseStart, fk.Damaged, fk.Damage, fk.TargetConfirming,
      fk.EnterDying, fk.AfterCardsMove, fk.CardUsing, fk.CardResponding, fk.AskForRetrial, fk.CardEffectCancelledOut, fk.Deathed,
      fk.FinishJudge, fk.TargetConfirmed, fk.ChainStateChanged, fk.HpChanged, fk.RoundStart, fk.DamageCaused, fk.DamageInflicted},
    times = function (self)
      local room = Fk:currentRoom()
      local info = room:getBanner("tianshu_skills")
      if info and info[self.name] and info[self.name][3] == Self.id then
        return 2 - Self:usedSkillTimes(self.name, Player.HistoryGame)
      else
        return 1 - Self:usedSkillTimes(self.name, Player.HistoryGame)
      end
    end,
    can_trigger = function(self, event, target, player, data)
      if player:hasSkill(self) then
        local room = player.room
        local info = room:getBanner("tianshu_skills")[self.name][1]
        if info == 1 then
          return event == fk.CardUseFinished and target == player
        elseif info == 2 then
          return event == fk.CardUseFinished and target ~= player and data.tos and
            table.contains(TargetGroup:getRealTargets(data.tos), player.id)
        elseif info == 3 then
          return event == fk.EventPhaseStart and target == player and player.phase == Player.Play
        elseif info == 4 then
          return event == fk.Damaged and target == player
        elseif info == 5 then
          return event == fk.EventPhaseStart and target == player and player.phase == Player.Start
        elseif info == 6 then
          return event == fk.EventPhaseStart and target == player and player.phase == Player.Finish
        elseif info == 7 then
          return event == fk.Damage and target == player
        elseif info == 8 then
          return event == fk.TargetConfirming and target == player and data.card.trueName == "slash"
        elseif info == 9 then
          return event == fk.EnterDying
        elseif info == 10 then
          if event == fk.AfterCardsMove then
            for _, move in ipairs(data) do
              if move.from == player.id then
                for _, inf in ipairs(move.moveInfo) do
                  if inf.fromArea == Card.PlayerEquip then
                    return true
                  end
                end
              end
            end
          end
        elseif info == 11 then
          return (event == fk.CardUsing or event == fk.CardResponding) and target == player and data.card.trueName == "jink"
        elseif info == 12 then
          return event == fk.AskForRetrial and data.card
        elseif info == 13 then
          if event == fk.AfterCardsMove then
            for _, move in ipairs(data) do
              if move.from == player.id then
                for _, inf in ipairs(move.moveInfo) do
                  if inf.fromArea == Card.PlayerHand then
                    return true
                  end
                end
              end
            end
          end
        elseif info == 14 then
          return event == fk.CardEffectCancelledOut and data.card
        elseif info == 15 then
          return event == fk.Deathed and target ~= player
        elseif info == 16 then
          return event == fk.FinishJudge and data.card
        elseif info == 17 then
          return event == fk.CardUseFinished and (data.card.trueName == "savage_assault" or data.card.trueName == "archery_attack")
        elseif info == 18 then
          return event == fk.Damage and target == player and data.card and data.card.trueName == "slash"
        elseif info == 19 then
          if event == fk.AfterCardsMove then
            if player.phase == Player.NotActive then
              for _, move in ipairs(data) do
                if move.from == player.id then
                  for _, inf in ipairs(move.moveInfo) do
                    if Fk:getCardById(inf.cardId).color == Card.Red and
                      (inf.fromArea == Card.PlayerHand or inf.fromArea == Card.PlayerEquip) then
                      return true
                    end
                  end
                end
              end
            end
          end
        elseif info == 20 then
          return event == fk.EventPhaseStart and target == player and player.phase == Player.Discard
        elseif info == 21 then
          return event == fk.Damaged and data.card and data.card.trueName == "slash"
        elseif info == 22 then
          return event == fk.EventPhaseStart and target == player and player.phase == Player.Draw
        elseif info == 23 then
          return event == fk.TargetConfirmed and target == player and data.card.type == Card.TypeTrick
        elseif info == 24 then
          return event == fk.ChainStateChanged and target.chained
        elseif info == 25 then
          return event == fk.Damaged and data.damageType ~= fk.NormalDamage
        elseif info == 26 then
          if event == fk.AfterCardsMove then
            for _, move in ipairs(data) do
              if move.from and room:getPlayerById(move.from):isKongcheng() then
                for _, inf in ipairs(move.moveInfo) do
                  if inf.fromArea == Card.PlayerHand then
                    return true
                  end
                end
              end
            end
          end
        elseif info == 27 then
          return event == fk.HpChanged and target == player
        elseif info == 28 then
          return event == fk.RoundStart
        elseif info == 29 then
          return event == fk.DamageCaused and target ~= nil
        elseif info == 30 then
          return event == fk.DamageInflicted
        end
      end
    end,
    on_cost = function(self, event, target, player, data)
      local room = player.room
      local info = room:getBanner("tianshu_skills")[self.name][2]
      local prompt = Fk:translate(":tianshu_effects"..info)
      self.cost_data = nil
      if info == 1 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 2 then
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return not p:isAllNude()
        end)
        if table.find(player:getCardIds("hej"), function (id)
          return not player:prohibitDiscard(id)
        end) then
          table.insert(targets, player)
        end
        if #targets == 0 then return end
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 3 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 4 then
        if player:isNude() then return end
        local cards = room:askForDiscard(player, 1, 999, true, self.name, true, nil, prompt, true)
        if #cards > 0 then
          self.cost_data = {cards = cards}
          return true
        end
      elseif info == 5 then
        if data.card and room:getCardArea(data.card) == Card.Processing then
          return room:askForSkillInvoke(player, self.name, nil, prompt)
        end
      elseif info == 6 then
        local use = U.askForUseVirtualCard(room, player, "slash", nil, self.name, prompt, true, true, true, true, nil, true)
        if use then
          self.cost_data = use
          return true
        end
      elseif info == 7 then
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return not p:isAllNude()
        end)
        if #player:getCardIds("ej") > 0 then
          table.insert(targets, player)
        end
        if #targets == 0 then return end
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 8 then
        if player:isWounded() then
          return room:askForSkillInvoke(player, self.name, nil, prompt)
        end
      elseif info == 9 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 10 then
        if player:getHandcardNum() < player.maxHp then
          return room:askForSkillInvoke(player, self.name, nil, prompt)
        end
      elseif info == 11 then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 12 then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 13 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 14 then
        local targets = room:getOtherPlayers(player, false)
        if #targets == 0 then return end
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 15 then
        if not player:isKongcheng() and data.card then
          local card = room:askForCard(player, 1, 1, false, self.name, true, nil, prompt)
          if #card > 0 then
            self.cost_data = {cards = card}
            return true
          end
        end
      elseif info == 16 then
        if data.card and room:getCardArea(data.card) == Card.Processing then
          return room:askForSkillInvoke(player, self.name, nil, prompt)
        end
      elseif info == 17 then
        if table.find(room.alive_players, function (p)
          return p.maxHp > player.maxHp
        end) then
          return room:askForSkillInvoke(player, self.name, nil, prompt)
        end
      elseif info == 18 then
        if player:isKongcheng() then return end
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return p:isWounded() and player:canPindian(p)
        end)
        if #targets == 0 then return end
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 19 then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 2, prompt, self.name, true)
        if #to > 0 then
          room:sortPlayersByAction(to)
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 20 then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 21 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 22 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 23 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 24 then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 25 then
        if #player:getCardIds("he") < 2 then return end
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return p:isWounded()
        end)
        if #targets == 0 then return end
        local ids = table.filter(player:getCardIds("he"), function (id)
          return not player:prohibitDiscard(id)
        end)
        local to, cards = room:askForChooseCardsAndPlayers(player, 2, 2, table.map(targets, Util.IdMapper), 1, 1,
          tostring(Exppattern{ id = ids }), prompt, self.name, true)
        if #to > 0 and #cards > 0 then
          self.cost_data = {tos = to, cards = cards}
          return true
        end
      elseif info == 26 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 27 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 28 then
        local success, dat = room:askForUseActiveSkill(player, "tianshu_active", prompt, true, {tianshu28 = "e"}, false)
        if success and dat then
          room:sortPlayersByAction(dat.targets)
          self.cost_data = {tos = dat.targets}
          return true
        end
      elseif info == 29 then
        local success, dat = room:askForUseActiveSkill(player, "tianshu_active", prompt, true, {tianshu28 = "h"}, false)
        if success and dat then
          room:sortPlayersByAction(dat.targets)
          self.cost_data = {tos = dat.targets}
          return true
        end
      elseif info == 30 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      end
    end,
    on_use = function(self, event, target, player, data)
      local room = player.room
      local info = room:getBanner("tianshu_skills")[self.name][2]
      local source = room:getBanner("tianshu_skills")[self.name][3]
      if source ~= player.id or player:usedSkillTimes(self.name, Player.HistoryGame) > 1 then
        room:handleAddLoseSkills(player, "-"..self.name, nil, true, false)
        local banner = room:getBanner("tianshu_skills")
        banner[self.name] = nil
        room:setBanner("tianshu_skills", banner)
      else
        local mark = player:getTableMark("@[tianshu]")
        for i = 1, #mark do
          if mark[i].skillName == self.name then
            mark[i].skillTimes = 2 - player:usedSkillTimes(self.name, Player.HistoryGame)
            mark[i].visible = true
            break
          end
        end
        room:setPlayerMark(player, "@[tianshu]", mark)
      end
      switch(info, {
        [1] = function ()
          player:drawCards(1, self.name)
        end,
        [2] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          if to == player then
            local cards = table.filter(player:getCardIds("hej"), function (id)
              return not player:prohibitDiscard(id)
            end)
            local card = room:askForCard(player, 1, 1, true, self.name, false, tostring(Exppattern{ id = cards }),
              "#tianshu2-discard::"..player.id, player:getCardIds("j"))
            room:throwCard(card, self.name, player, player)
          else
            local card = room:askForCardChosen(player, to, "hej", self.name, "#tianshu2-discard::"..to.id)
            room:throwCard(card, self.name, to, player)
          end
        end,
        [3] = function ()
          room:askForGuanxing(player, room:getNCards(3))
        end,
        [4] = function ()
          room:throwCard(self.cost_data.cards, self.name, player, player)
          if player.dead then return end
          player:drawCards(#self.cost_data.cards, self.name)
        end,
        [5] = function ()
          room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
        end,
        [6] = function ()
          room:useCard(self.cost_data)
        end,
        [7] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          local flag = to == player and "ej" or "hej"
          local card = room:askForCardChosen(player, to, flag, self.name, "#tianshu7-prey::"..to.id)
          room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
        end,
        [8] = function ()
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
          }
        end,
        [9] = function ()
          player:drawCards(3, self.name)
          if not player.dead then
            room:askForDiscard(player, 1, 1, true, self.name, false)
          end
        end,
        [10] = function ()
          player:drawCards(math.min(player.maxHp - player:getHandcardNum(), 5), self.name)
        end,
        [11] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          room:addPlayerMark(to, "@@tianshu11", 1)
          room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity, 1)
        end,
        [12] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          to:drawCards(2, self.name)
          if not to.dead then
            to:turnOver()
          end
        end,
        [13] = function ()
          table.insertIfNeed(data.nullifiedTargets, player.id)
        end,
        [14] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          local judge = {
            who = to,
            reason = self.name,
            pattern = ".|.|spade",
          }
          room:judge(judge)
          if judge.card.suit == Card.Spade and not to.dead then
            room:damage{
              from = player,
              to = to,
              damage = 2,
              damageType = fk.ThunderDamage,
              skillName = self.name,
            }
          end
        end,
        [15] = function ()
          local card = Fk:getCardById(self.cost_data.cards[1])
          room:retrial(card, player, data, self.name, true)
        end,
        [16] = function ()
          room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
        end,
        [17] = function ()
          room:changeMaxHp(player, 1)
        end,
        [18] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          local pindian = player:pindian({to}, self.name)
          if pindian.results[to.id].winner == player then
            if not player.dead and not to.dead and not to:isNude() then
              local cards = room:askForCardsChosen(player, to, math.min(#to:getCardIds("he"), 2), 2, "he", self.name,
                "#tianshu18-prey::"..to.id)
              room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
            end
          end
        end,
        [19] = function ()
          for _, id in ipairs(self.cost_data.tos) do
            local p = room:getPlayerById(id)
            if not p.dead then
              p:drawCards(1, self.name)
            end
          end
        end,
        [20] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          room:addPlayerMark(to, MarkEnum.AddMaxCards, 2)
          room:addPlayerMark(to, "tianshu20", 2)
        end,
        [21] = function ()
          local cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", 2)
          if #cards > 0 then
            room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id)
          end
        end,
        [22] = function ()
          local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick", 2)
          if #cards > 0 then
            room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id)
          end
        end,
        [23] = function ()
          player:drawCards(3, self.name)
          if not player.dead then
            player:turnOver()
          end
        end,
        [24] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          room:addTableMark(player, "tianshu24", to.id)
        end,
        [25] = function ()
          room:throwCard(self.cost_data.cards, self.name, player, player)
          local to = room:getPlayerById(self.cost_data.tos[1])
          if not player.dead and player:isWounded() then
            room:recover{
              who = player,
              num = 1,
              recoverBy = player,
              skillName = self.name
            }
          end
          if not to.dead and to:isWounded() then
            room:recover{
              who = to,
              num = 1,
              recoverBy = player,
              skillName = self.name
            }
          end
        end,
        [26] = function ()
          data.damage = data.damage + 1
        end,
        [27] = function ()
          room:loseHp(player, 1, self.name)
          if not player.dead then
            player:drawCards(3, self.name)
          end
        end,
        [28] = function ()
          local targets = table.map(self.cost_data.tos, Util.Id2PlayerMapper)
          room:swapAllCards(player, targets, self.name, "e")
        end,
        [29] = function ()
          local targets = table.map(self.cost_data.tos, Util.Id2PlayerMapper)
          room:swapAllCards(player, targets, self.name)
        end,
        [30] = function ()
          if data.from and not data.from.dead then
            data.from:drawCards(3, self.name)
          end
          return true
        end,
      })
    end,

    --几个持续一段时间的标记效果，在青书中清理。

    dynamic_desc = function(self, player)
      local mark = Fk:currentRoom():getBanner("tianshu_skills")
      if mark == nil then return self.name end
      local info = mark[self.name]
      if info == nil then return self.name end
      if player:usedSkillTimes(self.name, Player.HistoryGame) > 0 or Self:isBuddy(player) or Self:isBuddy(info[3]) then
        --FIXME:直接用翻译很不好
        return "tianshu_inner:" .. (info[3] == player.id and 2 or 1) - player:usedSkillTimes(self.name, Player.HistoryGame) .. ":" ..
        Fk:translate(":tianshu_triggers"..info[1]) .. ":" .. Fk:translate(":tianshu_effects"..info[2])
      else
        return "tianshu_unknown:" .. (info[3] == player.id and 2 or 1)
      end
      return self.name
    end,

    on_acquire = function (self, player, is_start)
      local room = player.room
      local info = room:getBanner("tianshu_skills")[self.name]

      --FIXME:理论上这个mark可不要了，但是要分离的逻辑太复杂了，懒得搞(=ﾟωﾟ)ﾉ

      local mark = player:getTableMark("@[tianshu]")
      table.insert(mark, {
        skillName = self.name,
        skillTimes = info[3] == player.id and 2 or 1,
        skillInfo = Fk:translate(":tianshu_triggers"..info[1]).."，"..Fk:translate(":tianshu_effects"..info[2]).."。",
        owner = { player.id, info[3] },
        visible = false
      })
      room:setPlayerMark(player, "@[tianshu]", mark)
    end,

    on_lose = function (self, player, is_death)
      local room = player.room
      local mark = player:getTableMark("@[tianshu]")
      for i = #mark, 1, -1 do
        if mark[i].skillName == self.name then
          table.remove(mark, i)
        end
      end
      room:setPlayerMark(player, "@[tianshu]", #mark > 0 and mark or 0)
      player:setSkillUseHistory(self.name, 0, Player.HistoryGame)
    end,
  }
  Fk:addSkill(tianshu)
  Fk:loadTranslationTable{
    ["tianshu"..loop] = "天书",
    [":tianshu"..loop] = "未翻开的天书。",
    ["tianshu_triggers"..loop] = "时机",
    ["tianshu_effects"..loop] = "效果",
  }
end
local tianshu_active = fk.CreateActiveSkill{
  name = "tianshu_active",
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards, _, extra_data)
    if #selected < 2 then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        local area = extra_data.tianshu28
        return #Fk:currentRoom():getPlayerById(selected[1]):getCardIds(area) > 0 or
          #Fk:currentRoom():getPlayerById(to_select):getCardIds(area) > 0
      end
    end
  end,
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
Fk:addSkill(tianshu_active)
nanhualaoxian:addSkill(qingshu)
nanhualaoxian:addSkill(ol__shoushu)
nanhualaoxian:addSkill(hedao)
Fk:loadTranslationTable{
  ["ol__nanhualaoxian"] = "南华老仙",
  ["#ol__nanhualaoxian"] = "逍遥仙游",
  --["designer:ol__nanhualaoxian"] = "",

  ["qingshu"] = "青书",
  [":qingshu"] = "锁定技，游戏开始时，你的准备阶段和结束阶段，你书写一册<a href='tianshu_href'>“天书”</a>。",
  ["ol__shoushu"] = "授术",
  [":ol__shoushu"] = "出牌阶段限一次，你可以将一册未翻开的<a href='tianshu_href'>“天书”</a>交给一名其他角色。",
  ["tianshu_href"] = "从随机三个时机和三个效果中各选择一个组合为一个“天书”技能。<br>"..
    "“天书”技能初始可使用两次，若交给其他角色则可使用次数改为一次，当次数用完后销毁。<br>"..
    "当一名角色将获得“天书”时，若数量将超过其可拥有“天书”的上限，则选择一个已有“天书”替换。",
  ["#qingshu-choice_trigger"] = "请为天书选择一个时机",
  ["#qingshu-choice_effect"] = "请为此时机选择一个效果：<br>%arg，",
  ["#ol__shoushu-discard"] = "你的“天书”超出上限，请删除一个",
  ["#ol__shoushu"] = "授术：你可以将一册未翻开的“天书”交给一名其他角色",
  ["#ol__shoushu-give"] = "授术：选择交给 %dest 的“天书”",

  ["@[tianshu]"] = "天书",
  ["#tianshu2-discard"] = "弃置 %dest 区域内一张牌",
  ["#tianshu7-prey"] = "获得 %dest 区域内一张牌",
  ["#tianshu18-prey"] = "获得 %dest 两张牌",
  ["@@tianshu11"] = "非锁定技失效",
  ["tianshu_active"] = "天书",

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

  ["$qingshu1"] = "赤紫青黄，唯记万变其一。",
  ["$qingshu2"] = "天地万法，皆在此书之中。",
  ["$qingshu3"] = "以小篆记大道，则道可道。",
  ["$ol__shoushu1"] = "此书载天地至理，望汝珍视如命。",
  ["$ol__shoushu2"] = "天书非凡物，字字皆玄机。",
  ["$ol__shoushu3"] = "我得道成仙，当出世化生人中。",
  ["~ol__nanhualaoxian"] = "尔生异心，必获恶报！",
}
