local yuheng = fk.CreateSkill{
  name = "yuheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yuheng"] = "驭衡",
  [":yuheng"] = "锁定技，回合开始时，你弃置任意张花色不同的牌，随机获得等量吴势力武将的技能。回合结束时，你失去以此法获得的技能，摸等量张牌。",

  ["#yuheng-invoke"] = "驭衡：弃置任意张花色不同的牌，随机获得等量吴势力武将的技能",

  ["$yuheng1"] = "权术妙用，存乎一心。",
  ["$yuheng2"] = "威权之道，皆在于衡。",
}

local yuheng_skills = {
  "ex__zhiheng", "dimeng", "anxu", "ol__bingyi", "shenxing",
  "xingxue", "anguo", "jiexun", "xiashu", "ol__hongyuan",
  "lanjiang", "sp__youdi", "guanwei", "ol__diaodu", "bizheng"
}

yuheng:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuheng.name) and
      table.find(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id) and Fk:getCardById(id).suit ~= Card.NoSuit
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "yuheng_active",
      prompt = "#yuheng-invoke",
      cancelable = false,
    })
    if not (success and dat) then
      dat = {}
      local cards = table.filter(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id) and Fk:getCardById(id).suit ~= Card.NoSuit
      end)
      dat.cards = {cards[1]}
    end
    room:throwCard(dat.cards, yuheng.name, player, player)
    if player.dead then return end
    local skills = table.filter(yuheng_skills, function (s)
      return Fk.skill_skels[s] and not player:hasSkill(s, true)
    end)
    if #skills == 0 then return end
    skills = table.random(skills, #dat.cards)
    local mark = player:getTableMark("yuheng-turn")
    table.insertTableIfNeed(mark, skills)
    room:setPlayerMark(player, "yuheng-turn", mark)
    room:handleAddLoseSkills(player, table.concat(skills, "|"))
  end,
})
yuheng:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("yuheng-turn") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = player:getMark("yuheng-turn")
    skills = table.filter(skills, function (s)
      return Fk.skill_skels[s] and player:hasSkill(s, true)
    end)
    if #skills == 0 then return end
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
    if not player.dead then
      player:drawCards(#skills, yuheng.name)
    end
  end,
})

return yuheng
