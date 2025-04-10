local jiewu = fk.CreateSkill{
  name = "jiewu",
}

Fk:loadTranslationTable{
  ["jiewu"] = "捷悟",
  [":jiewu"] = "出牌阶段开始时，你可以令一名角色的手牌此阶段始终对你可见。然后你此阶段使用牌指定其他角色为目标后，你可以展示“捷悟”角色"..
  "一张手牌，若两张牌花色相同，你摸一张牌；若此牌本回合以此法展示过，你将你与其之中手牌较多的角色一张牌置于牌堆顶。",

  ["#jiewu-choose"] = "捷悟：选择一名角色，其手牌此阶段对你可见",
  ["@@jiewu-phase"] = "捷悟",
  ["#jiewu-invoke"] = "捷悟：是否展示 %dest 一张手牌，若与你使用的牌花色相同则摸牌",
  ["#jiewu-show"] = "捷悟：展示 %dest 一张手牌",
  ["#jiewu-ask"] = "捷悟：将 %dest 一张牌置于牌堆顶",
}

jiewu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jiewu.name) and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = jiewu.name,
      prompt = "#jiewu-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:setPlayerMark(to, "@@jiewu-phase", player.id)
  end,
})
jiewu:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:usedSkillTimes(jiewu.name, Player.HistoryPhase) > 0 and data.firstTarget and
      table.find(player.room.alive_players, function (p)
        return p:getMark("@@jiewu-phase") == player.id and not p:isKongcheng()
      end) and
      table.find(data.use.tos, function (p)
        return p ~= player
      end) and
      not player.dead
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = table.find(room.alive_players, function (p)
      return p:getMark("@@jiewu-phase") == player.id and not p:isKongcheng()
    end)
    if to == nil then return end
    if room:askToSkillInvoke(player, {
      skill_name = jiewu.name,
      prompt = "#jiewu-invoke::"..to.id,
    }) then
      event:setCostData(self, {tos = {to}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = table.find(room.alive_players, function (p)
      return p:getMark("@@jiewu-phase") == player.id and not p:isKongcheng()
    end)
    if to == nil then return end
    local id
    if to == player then
      id = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = jiewu.name,
        prompt = "#jiewu-show::"..player.id,
        cancelable = false,
      })[1]
    else
      id = room:askToChooseCard(player, {
        target = to,
        flag = "h",
        skill_name = jiewu.name,
        prompt = "#jiewu-show::"..to.id,
      })
    end
    local yes = Fk:getCardById(id):compareSuitWith(data.card)
    local put = table.contains(player:getTableMark("jiewu-turn"), id)
    room:addTableMarkIfNeed(player, "jiewu-turn", id)
    to:showCards(id)
    if player.dead then return end
    if yes then
      player:drawCards(1, jiewu.name)
      if player.dead then return end
    end
    if put then
      if player:getHandcardNum() > to:getHandcardNum() then
        id = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = jiewu.name,
          prompt = "#jiewu-ask::"..player.id,
          cancelable = false,
        })
        room:moveCards({
          ids = id,
          from = player,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = jiewu.name,
        })
      elseif player:getHandcardNum() < to:getHandcardNum() and not to.dead then
        room:doIndicate(player, {to})
        id = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = jiewu.name,
          prompt = "#jiewu-ask::"..to.id,
        })
        room:moveCards({
          ids = {id},
          from = to,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = jiewu.name,
        })
      end
    end
  end,
})

jiewu:addEffect("visibility", {
  card_visible = function (self, player, card)
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:getMark("@@jiewu-phase") == player.id and table.contains(p:getCardIds("h"), card.id) then
        return true
      end
    end
  end,
})

return jiewu
