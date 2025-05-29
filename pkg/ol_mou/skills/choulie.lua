local choulie = fk.CreateSkill{
  name = "choulie",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["choulie"] = "仇猎",
  [":choulie"] = "限定技，回合开始时，你可以选择一名其他角色，本回合你的每个阶段开始时，你可以弃置一张牌视为对其使用一张【杀】，"..
  "其可以弃置一张基本牌或武器牌令此【杀】无效。",

  ["#choulie-choose"] = "仇猎：选择一名角色，本回合每个阶段开始时，你可以弃一张牌视为对其使用【杀】！",
  ["@@choulie-turn"] = "仇猎",
  ["#choulie-slash"] = "仇猎：是否弃置一张牌，视为对 %dest 使用一张【杀】？",
  ["#choulie-discard"] = "仇猎：是否弃置一张基本牌或武器牌，令此【杀】对你无效？",

  ["$choulie1"] = "匹夫欺我太甚！此仇不死不休！",
  ["$choulie2"] = "唯有那曹操项上人头，方能解我心头之恨！",
}

choulie:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(choulie.name)
      and player:usedSkillTimes(choulie.name, Player.HistoryGame) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = choulie.name,
      prompt = "#choulie-choose",
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
    room:setPlayerMark(to, "@@choulie-turn", 1)
    room:setPlayerMark(player, "choulie-turn", to.id)
  end,
})

choulie:addEffect(fk.EventPhaseStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:usedSkillTimes(choulie.name, Player.HistoryTurn) > 0 and
      player.phase >= Player.Start and player.phase <= Player.Finish and not player:isNude() and not player.dead then
      local to = player.room:getPlayerById(player:getMark("choulie-turn"))
      return not to.dead and player:canUseTo(Fk:cloneCard("slash"), to, {bypass_distances = true, bypass_times = true})
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = choulie.name,
      cancelable = true,
      prompt = "#choulie-slash::"..player:getMark("choulie-turn"),
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(choulie.name)
    --room:notifySkillInvoked(player, choulie.name, "offensive")
    local to = room:getPlayerById(player:getMark("choulie-turn"))
    room:throwCard(event:getCostData(self).cards, choulie.name, player, player)
    if not to.dead then
      local card = Fk:cloneCard("slash")
      card.skillName = choulie.name
      local use = {
        from = player,
        tos = {to},
        card = card,
        extraUse = true,
        extra_data = {
          choulie = player
        },
      }
      room:useCard(use)
    end
  end,
})
choulie:addEffect(fk.TargetConfirmed, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, choulie.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = choulie.name,
      cancelable = true,
      pattern = ".|.|.|.|.|basic,weapon",
      prompt = "#choulie-discard",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, choulie.name, player, player)
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)
  end,
})

return choulie
