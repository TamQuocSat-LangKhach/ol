local skels = {}

for loop = 1, 30 do
  local tianshu = fk.CreateSkill{
    name = "tianshu"..loop,
    dynamic_desc = function(self, player)
      local mark = Fk:currentRoom():getBanner("tianshu_skills")
      if mark == nil then return self.name end
      local info = mark[self.name]
      if info == nil then return self.name end
      if player:usedSkillTimes(self.name, Player.HistoryGame) > 0 or Self:isBuddy(player) or Self:isBuddy(info[3]) then
        return "tianshu_inner:" .. (info[3] == player.id and 2 or 1) - player:usedSkillTimes(self.name, Player.HistoryGame) .. ":" ..
        Fk:translate(":tianshu_triggers"..info[1]) .. ":" .. Fk:translate(":tianshu_effects"..info[2])
      else
        return "tianshu_unknown:" .. (info[3] == player.id and 2 or 1)
      end
    end,
  }

  local spec = {
    times = function (self, player)
      local room = Fk:currentRoom()
      local info = room:getBanner("tianshu_skills")
      if info and info[tianshu.name] and info[tianshu.name][3] == player.id then
        return 2 - player:usedSkillTimes(tianshu.name, Player.HistoryGame)
      else
        return 1 - player:usedSkillTimes(tianshu.name, Player.HistoryGame)
      end
    end,
    can_trigger = function(self, event, target, player, data)
      if player:hasSkill(tianshu.name) then
        local room = player.room
        local info = room:getBanner("tianshu_skills")[tianshu.name][1]
        if info == 1 then
          return event == fk.CardUseFinished and target == player
        elseif info == 2 then
          return event == fk.CardUseFinished and target ~= player and data.tos and table.contains(data.tos, player)
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
              if move.from == player then
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
              if move.from == player then
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
            if player.room.current ~= player then
              for _, move in ipairs(data) do
                if move.from == player then
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
              if move.from and move.from:isKongcheng() then
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
      local info = room:getBanner("tianshu_skills")[tianshu.name][2]
      local prompt = Fk:translate(":tianshu_effects"..info)
      event:setCostData(self, nil)
      if info == 1 then
        return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
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
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = prompt,
          skill_name = tianshu.name,
          cancelable = true,
        })
        if #to > 0 then
          event:setCostData(self, {tos = to})
          return true
        end
      elseif info == 3 then
        return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
      elseif info == 4 then
        if player:isNude() then return end
        local cards = room:askToDiscard(player, {
          min_num = 1,
          max_num = 999,
          include_equip = true,
          skill_name = tianshu.name,
          prompt = prompt,
          cancelable = true,
          skip = true,
        })
        if #cards > 0 then
          event:setCostData(self, {cards = cards})
          return true
        end
      elseif info == 5 then
        if data.card and room:getCardArea(data.card) == Card.Processing then
          return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
        end
      elseif info == 6 then
        local use = room:askToUseVirtualCard(player, {
          name = "slash",
          skill_name = tianshu.name,
          prompt = prompt,
          cancelable = true,
          extra_data = {
            bypass_distances = true,
            bypass_times = true,
            extraUse = true,
          },
          skip = true,
        })
        if use then
          event:setCostData(self, {extra_data = use})
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
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = prompt,
          skill_name = tianshu.name,
          cancelable = true,
        })
        if #to > 0 then
          event:setCostData(self, {tos = to})
          return true
        end
      elseif info == 8 then
        if player:isWounded() then
          return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
        end
      elseif info == 9 then
        return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
      elseif info == 10 then
        if player:getHandcardNum() < player.maxHp then
          return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
        end
      elseif info == 11 then
        local to = room:askToChoosePlayers(player, {
          targets = room.alive_players,
          min_num = 1,
          max_num = 1,
          prompt = prompt,
          skill_name = tianshu.name,
          cancelable = true,
        })
        if #to > 0 then
          event:setCostData(self, {tos = to})
          return true
        end
      elseif info == 12 then
        local to = room:askToChoosePlayers(player, {
          targets = room.alive_players,
          min_num = 1,
          max_num = 1,
          prompt = prompt,
          skill_name = tianshu.name,
          cancelable = true,
        })
        if #to > 0 then
          event:setCostData(self, {tos = to})
          return true
        end
      elseif info == 13 then
        return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
      elseif info == 14 then
        local targets = room:getOtherPlayers(player, false)
        if #targets == 0 then return end
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = prompt,
          skill_name = tianshu.name,
          cancelable = true,
        })
        if #to > 0 then
          event:setCostData(self, {tos = to})
          return true
        end
      elseif info == 15 then
        if not player:isKongcheng() and data.card then
          local card = room:askToCards(player, {
            min_num = 1,
            max_num = 1,
            include_equip = false,
            skill_name = tianshu.name,
            prompt = prompt,
            cancelable = true,
          })
          if #card > 0 then
            event:setCostData(self, {cards = card})
            return true
          end
        end
      elseif info == 16 then
        if data.card and room:getCardArea(data.card) == Card.Processing then
          return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
        end
      elseif info == 17 then
        if table.find(room.alive_players, function (p)
          return p.maxHp > player.maxHp
        end) then
          return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
        end
      elseif info == 18 then
        if player:isKongcheng() then return end
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return p:isWounded() and player:canPindian(p)
        end)
        if #targets == 0 then return end
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = prompt,
          skill_name = tianshu.name,
          cancelable = true,
        })
        if #to > 0 then
          event:setCostData(self, {tos = to})
          return true
        end
      elseif info == 19 then
        local to = room:askToChoosePlayers(player, {
          targets = room.alive_players,
          min_num = 1,
          max_num = 2,
          prompt = prompt,
          skill_name = tianshu.name,
          cancelable = true,
        })
        if #to > 0 then
          room:sortByAction(to)
          event:setCostData(self, {tos = to})
          return true
        end
      elseif info == 20 then
        local to = room:askToChoosePlayers(player, {
          targets = room.alive_players,
          min_num = 1,
          max_num = 1,
          prompt = prompt,
          skill_name = tianshu.name,
          cancelable = true,
        })
        if #to > 0 then
          event:setCostData(self, {tos = to})
          return true
        end
      elseif info == 21 then
        return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
      elseif info == 22 then
        return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
      elseif info == 23 then
        return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
      elseif info == 24 then
        local to = room:askToChoosePlayers(player, {
          targets = room.alive_players,
          min_num = 1,
          max_num = 1,
          prompt = prompt,
          skill_name = tianshu.name,
          cancelable = true,
        })
        if #to > 0 then
          event:setCostData(self, {tos = to})
          return true
        end
      elseif info == 25 then
        if #player:getCardIds("he") < 2 then return end
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return p:isWounded()
        end)
        if #targets == 0 then return end
        local to, cards = room:askToChooseCardsAndPlayers(player, {
          min_card_num = 2,
          max_card_num = 2,
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = tianshu.name,
          prompt = prompt,
          cancelable = true,
          will_throw = true,
        })
        if #to > 0 and #cards > 0 then
          event:setCostData(self, {tos = to, cards = cards})
          return true
        end
      elseif info == 26 then
        return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
      elseif info == 27 then
        return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
      elseif info == 28 then
        local success, dat = room:askToUseActiveSkill(player, {
          skill_name = "tianshu_active",
          prompt = prompt,
          cancelable = true,
          extra_data = {
            tianshu28 = "e",
          }
        })
        if success and dat then
          room:sortByAction(dat.targets)
          event:setCostData(self, {tos = dat.targets})
          return true
        end
      elseif info == 29 then
        local success, dat = room:askToUseActiveSkill(player, {
          skill_name = "tianshu_active",
          prompt = prompt,
          cancelable = true,
          extra_data = {
            tianshu28 = "h",
          }
        })
        if success and dat then
          room:sortByAction(dat.targets)
          event:setCostData(self, {tos = dat.targets})
          return true
        end
      elseif info == 30 then
        return room:askToSkillInvoke(player, {
          skill_name = tianshu.name,
          prompt = prompt,
        })
      end
    end,
    on_use = function(self, event, target, player, data)
      local room = player.room
      local info = room:getBanner("tianshu_skills")[tianshu.name][2]
      local source = room:getBanner("tianshu_skills")[tianshu.name][3]
      if source ~= player.id or player:usedSkillTimes(tianshu.name, Player.HistoryGame) > 1 then
        room:handleAddLoseSkills(player, "-"..tianshu.name)
        local banner = room:getBanner("tianshu_skills")
        banner[tianshu.name] = nil
        room:setBanner("tianshu_skills", banner)
      else
        local mark = player:getTableMark("@[tianshu]")
        for i = 1, #mark do
          if mark[i].skillName == tianshu.name then
            mark[i].skillTimes = 2 - player:usedSkillTimes(tianshu.name, Player.HistoryGame)
            mark[i].visible = true
            break
          end
        end
        room:setPlayerMark(player, "@[tianshu]", mark)
      end
      switch(info, {
        [1] = function ()
          player:drawCards(1, tianshu.name)
        end,
        [2] = function ()
          local to = event:getCostData(self).tos[1]
          if to == player then
            local cards = table.filter(player:getCardIds("hej"), function (id)
              return not player:prohibitDiscard(id)
            end)
            local card = room:askToCards(player, {
              min_num = 1,
              max_num = 1,
              include_equip = true,
              skill_name = tianshu.name,
              pattern = tostring(Exppattern{ id = cards }),
              prompt = "#tianshu2-discard::"..player.id,
              cancelable = false,
              expand_pile = player:getCardIds("j"),
            })
            room:throwCard(card, tianshu.name, player, player)
          else
            local card = room:askToChooseCard(player, {
              target = to,
              flag = "hej",
              skill_name = tianshu.name,
              prompt = "#tianshu2-discard::"..to.id,
            })
            room:throwCard(card, tianshu.name, to, player)
          end
        end,
        [3] = function ()
          room:askToGuanxing(player, {cards = room:getNCards(3)})
        end,
        [4] = function ()
          room:throwCard(event:getCostData(self).cards, tianshu.name, player, player)
          if player.dead then return end
          player:drawCards(#event:getCostData(self).cards, tianshu.name)
        end,
        [5] = function ()
          room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, tianshu.name, nil, true, player.id)
        end,
        [6] = function ()
          room:useCard(event:getCostData(self).extra_data)
        end,
        [7] = function ()
          local to = event:getCostData(self).tos[1]
          local flag = to == player and "ej" or "hej"
          local card = room:askToChooseCard(player, {
            target = to,
            flag = flag,
            skill_name = tianshu.name,
            prompt = "#tianshu7-prey::"..to.id,
          })
          room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, tianshu.name, nil, false, player)
        end,
        [8] = function ()
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = tianshu.name
          }
        end,
        [9] = function ()
          player:drawCards(3, tianshu.name)
          if not player.dead then
            room:askToDiscard(player, {
              min_num = 1,
              max_num = 1,
              include_equip = true,
              skill_name = tianshu.name,
              cancelable = false,
            })
          end
        end,
        [10] = function ()
          player:drawCards(math.min(player.maxHp - player:getHandcardNum(), 5), tianshu.name)
        end,
        [11] = function ()
          local to = event:getCostData(self).tos[1]
          room:addPlayerMark(to, "@@tianshu11", 1)
          room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity, 1)
        end,
        [12] = function ()
          local to = event:getCostData(self).tos[1]
          to:drawCards(2, tianshu.name)
          if not to.dead then
            to:turnOver()
          end
        end,
        [13] = function ()
          table.insertIfNeed(data.nullifiedTargets, player.id)
        end,
        [14] = function ()
          local to = event:getCostData(self).tos[1]
          local judge = {
            who = to,
            reason = tianshu.name,
            pattern = ".|.|spade",
          }
          room:judge(judge)
          if judge:matchPattern() and not to.dead then
            room:damage{
              from = player,
              to = to,
              damage = 2,
              damageType = fk.ThunderDamage,
              skillName = tianshu.name,
            }
          end
        end,
        [15] = function ()
          room:changeJudge{
            card = Fk:getCardById(event:getCostData(self).cards[1]),
            player = player,
            data = data,
            skillName = tianshu.name,
          }
        end,
        [16] = function ()
          room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, tianshu.name, nil, true, player)
        end,
        [17] = function ()
          room:changeMaxHp(player, 1)
        end,
        [18] = function ()
          local to = event:getCostData(self).tos[1]
          local pindian = player:pindian({to}, tianshu.name)
          if pindian.results[to].winner == player then
            if not player.dead and not to.dead and not to:isNude() then
              local cards = room:askToChooseCards(player, {
                target = to,
                min = 2,
                max = 2,
                flag = "he",
                skill_name = tianshu.name,
                prompt = "#tianshu18-prey::"..to.id,
              })
              room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, tianshu.name, nil, false, player)
            end
          end
        end,
        [19] = function ()
          for _, p in ipairs(event:getCostData(self).tos) do
            if not p.dead then
              p:drawCards(1, tianshu.name)
            end
          end
        end,
        [20] = function ()
          local to = event:getCostData(self).tos[1]
          room:addPlayerMark(to, MarkEnum.AddMaxCards, 2)
          room:addPlayerMark(to, "tianshu20", 2)
        end,
        [21] = function ()
          local cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", 2)
          if #cards > 0 then
            room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, tianshu.name, nil, false, player)
          end
        end,
        [22] = function ()
          local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick", 2)
          if #cards > 0 then
            room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, tianshu.name, nil, false, player)
          end
        end,
        [23] = function ()
          player:drawCards(3, tianshu.name)
          if not player.dead then
            player:turnOver()
          end
        end,
        [24] = function ()
          local to = event:getCostData(self).tos[1]
          room:addTableMark(player, "tianshu24", to.id)
        end,
        [25] = function ()
          room:throwCard(event:getCostData(self).cards, tianshu.name, player, player)
          local to = event:getCostData(self).tos[1]
          if not player.dead and player:isWounded() then
            room:recover{
              who = player,
              num = 1,
              recoverBy = player,
              skillName = tianshu.name,
            }
          end
          if not to.dead and to:isWounded() then
            room:recover{
              who = to,
              num = 1,
              recoverBy = player,
              skillName = tianshu.name,
            }
          end
        end,
        [26] = function ()
          data:changeDamage(1)
        end,
        [27] = function ()
          room:loseHp(player, 1, tianshu.name)
          if not player.dead then
            player:drawCards(3, tianshu.name)
          end
        end,
        [28] = function ()
          room:swapAllCards(player, event:getCostData(self).tos, tianshu.name, "e")
        end,
        [29] = function ()
          room:swapAllCards(player, event:getCostData(self).tos, tianshu.name)
        end,
        [30] = function ()
          data:preventDamage()
          if data.from and not data.from.dead then
            data.from:drawCards(3, tianshu.name)
          end
        end,
      })
    end,
  }

  for _, e in ipairs({
    fk.CardUseFinished, fk.EventPhaseStart, fk.Damaged, fk.Damage, fk.TargetConfirming,
    fk.EnterDying, fk.AfterCardsMove, fk.CardUsing, fk.CardResponding, fk.AskForRetrial,
    fk.CardEffectCancelledOut, fk.Deathed, fk.FinishJudge, fk.TargetConfirmed, fk.ChainStateChanged,
    fk.HpChanged, fk.RoundStart, fk.DamageCaused, fk.DamageInflicted}) do
    tianshu:addEffect(e, spec)
  end

  tianshu:addAcquireEffect(function (self, player, is_start)
    local room = player.room
    local info = room:getBanner("tianshu_skills")[tianshu.name]

    local mark = player:getTableMark("@[tianshu]")
    table.insert(mark, {
      skillName = tianshu.name,
      skillTimes = info[3] == player.id and 2 or 1,
      skillInfo = Fk:translate(":tianshu_triggers"..info[1]).."，"..Fk:translate(":tianshu_effects"..info[2]).."。",
      owner = { player.id, info[3] },
      visible = false,
    })
    room:setPlayerMark(player, "@[tianshu]", mark)
  end)

  tianshu:addLoseEffect(function (self, player, is_death)
    local room = player.room
    local mark = player:getTableMark("@[tianshu]")
    for i = #mark, 1, -1 do
      if mark[i].skillName == tianshu.name then
        table.remove(mark, i)
      end
    end
    room:setPlayerMark(player, "@[tianshu]", #mark > 0 and mark or 0)
    player:setSkillUseHistory(tianshu.name, 0, Player.HistoryGame)
  end)

  Fk:loadTranslationTable{
    ["tianshu"..loop] = "天书",
    [":tianshu"..loop] = "未翻开的天书。",
    ["tianshu_triggers"..loop] = "时机",
    ["tianshu_effects"..loop] = "效果",
  }

  table.insert(skels, tianshu)
end

return skels
