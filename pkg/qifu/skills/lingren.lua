local lingren = fk.CreateSkill{
  name = "lingren",
}

Fk:loadTranslationTable{
  ["lingren"] = "凌人",
  [":lingren"] = "每回合限一次，当你使用【杀】或伤害类锦囊牌指定第一个目标后，"..
  "你可以猜测其中一名目标角色的手牌区中是否有基本牌、锦囊牌或装备牌。"..
  "若你猜对：至少一项，此牌对其造成的伤害+1；至少两项，你摸两张牌；三项，你获得〖奸雄〗和〖行殇〗直到你的下个回合开始。",

  ["#lingren-choose"] = "凌人：猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["#lingren-invoke"] = "凌人：是否对 %dest 发动，猜测其手牌中是否有基本牌、锦囊牌或装备牌",
  ["#lingren-choice"] = "凌人：猜测 %dest 的手牌中是否有基本牌、锦囊牌或装备牌",
  ["lingren_basic"] = "有基本牌",
  ["lingren_trick"] = "有锦囊牌",
  ["lingren_equip"] = "有装备牌",
  ["#lingren_result"] = "%from 猜对了 %arg 项",

  ["$lingren1"] = "敌势已缓，休要走了老贼！",
  ["$lingren2"] = "精兵如炬，困龙难飞！",
}

lingren:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lingren.name) and
      data.firstTarget and data.card.is_damage_card and
      player:usedSkillTimes(lingren.name, Player.HistoryTurn) == 0 and
      table.find(data.use.tos, function (p)
        return not p.dead
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.use.tos, function (p)
      return not p.dead
    end)
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = lingren.name,
        prompt = "#lingren-invoke::" .. targets[1].id,
      }) then
        event:setCostData(self, {tos = targets})
        return true
      end
    else
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#lingren-choose",
        skill_name = lingren.name,
        cancelable = true,
      })
      if #targets > 0 then
        event:setCostData(self, {tos = targets})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choices = {"lingren_basic", "lingren_trick", "lingren_equip"}
    local yes = room:askToChoices(player, {
      choices = choices,
      min_num = 0,
      max_num = 3,
      skill_name = lingren.name,
      prompt = "#lingren-choice::"..to.id,
      cancelable = false,
    })
    for _, value in ipairs(yes) do
      table.removeOne(choices, value)
    end
    local right = 0
    for _, id in ipairs(to:getCardIds("h")) do
      local str = "lingren_"..Fk:getCardById(id):getTypeString()
      if table.contains(yes, str) then
        right = right + 1
        table.removeOne(yes, str)
      else
        table.removeOne(choices, str)
      end
    end
    right = right + #choices
    room:sendLog{
      type = "#lingren_result",
      from = player.id,
      arg = tostring(right),
      toast = true,
    }
    if right > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.lingren = data.extra_data.lingren or {}
      table.insert(data.extra_data.lingren, to.id)
    end
    if right > 1 then
      player:drawCards(2, lingren.name)
      if player.dead then return end
    end
    if right > 2 then
      local skills = {}
      if not player:hasSkill("ex__jianxiong", true) then
        table.insert(skills, "ex__jianxiong")
      end
      if not player:hasSkill("xingshang", true) then
        table.insert(skills, "xingshang")
      end
      if #skills > 0 then
        room:setPlayerMark(player, lingren.name, skills)
        room:handleAddLoseSkills(player, table.concat(skills, "|"))
      end
    end
  end,
})
lingren:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or target ~= player then return false end
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not use_event then return false end
    local use = use_event.data
    return use.extra_data and use.extra_data.lingren and table.contains(use.extra_data.lingren, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})
lingren:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(lingren.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = player:getMark(lingren.name)
    room:setPlayerMark(player, lingren.name, 0)
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
  end,
})

return lingren
