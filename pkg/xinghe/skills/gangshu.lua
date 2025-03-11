local gangshu = fk.CreateSkill{
  name = "gangshu",
}

Fk:loadTranslationTable{
  ["gangshu"] = "刚述",
  [":gangshu"] = "当你使用非基本牌后，你可以令你以下一项数值+1直到你抵消牌（至多增加至5）：攻击范围；下个摸牌阶段摸牌数；"..
  "出牌阶段使用【杀】次数上限。",

  ["gangshu1"] = "攻击范围",
  ["gangshu2"] = "下个摸牌阶段摸牌数",
  ["gangshu3"] = "出牌阶段使用【杀】次数",
  ["#gangshu-choice"] = "刚述：选择你要增加的一项",
  ["@[gangshu]"] = "刚述",

  ["$gangshu1"] = "羲而立之年，当为立身之事。",
  ["$gangshu2"] = "总六军之要，秉选举之机。",
}

local function gangshuTimesCheck(player, card)
  local status_skills = Fk:currentRoom().status_skills[TargetModSkill] or Util.DummyTable
  for _, skill in ipairs(status_skills) do
    if skill:bypassTimesCheck(player, card.skill, Player.HistoryPhase, card) then return true end
  end
  return false
end

Fk:addQmlMark{
  name = "gangshu",
  qml_path = "",
  how_to_show = function(name, value, p)
    local card = Fk:cloneCard("slash")
    local x1 = ""
    if p:getAttackRange() > 99 then
      x1 = "∞"
    else
      x1 = tostring(p:getAttackRange())
    end
    local x2 = tostring(p:getMark("gangshu2_fix")+2)
    local x3 = ""
    if gangshuTimesCheck(p, card) then
      x3 = "∞"
    else
      x3 = tostring(card.skill:getMaxUseTime(p, Player.HistoryPhase, card, nil) or "∞")
    end
    return x1 .. " " .. x2 .. " " .. x3
  end,
}

gangshu:addAcquireEffect(function (self, player, is_start)
  player.room:setPlayerMark(player, "@[gangshu]", 1)
end)

gangshu:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@[gangshu]", 0)
  room:setPlayerMark(player, "gangshu1_fix", 0)
  room:setPlayerMark(player, "gangshu2_fix", 0)
  room:setPlayerMark(player, "gangshu3_fix", 0)
end)

gangshu:addEffect(fk.CardUseFinished, {
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(gangshu.name) and data.card.type ~= Card.TypeBasic then
      if player:getMark("gangshu2_fix") < 3 then return true end
      if player:getAttackRange() < 5 then return true end
      local card = Fk:cloneCard("slash")
      return not gangshuTimesCheck(player, card) and (card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil) or 5) < 5
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if player:getAttackRange() < 5 then
      table.insert(choices, "gangshu1")
    end
    if player:getMark("gangshu2_fix") < 3 then
      table.insert(choices, "gangshu2")
    end
    local card = Fk:cloneCard("slash")
    if not gangshuTimesCheck(player, card) and (card.skill:getMaxUseTime(player, Player.HistoryPhase, card, nil) or 5) < 5 then
      table.insert(choices, "gangshu3")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = gangshu.name,
      prompt = "#gangshu-choice",
      all_choices = {"gangshu1", "gangshu2", "gangshu3", "Cancel"},
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, event:getCostData(self).choice.."_fix", 1)
  end,
})
gangshu:addEffect(fk.CardEffecting, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(gangshu.name, true) and data.toCard and data.from == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "gangshu1_fix", 0)
    room:setPlayerMark(player, "gangshu2_fix", 0)
    room:setPlayerMark(player, "gangshu3_fix", 0)
  end,
})
gangshu:addEffect(fk.DrawNCards, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("gangshu2_fix") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.n = data.n + player:getMark("gangshu2_fix")
    player.room:setPlayerMark(player, "gangshu2_fix", 0)
  end,
})
gangshu:addEffect("atkrange", {
  correct_func = function (self, from, to)
    return from:getMark("gangshu1_fix")
  end,
})
gangshu:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("gangshu3_fix") > 0 and scope == Player.HistoryPhase then
      return player:getMark("gangshu3_fix")
    end
  end,
})

return gangshu
