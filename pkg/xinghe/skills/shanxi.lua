local shanxi = fk.CreateSkill{
  name = "shanxi",
}

Fk:loadTranslationTable{
  ["shanxi"] = "闪袭",
  [":shanxi"] = "出牌阶段限一次，你可以展示你与一名攻击范围内不包含你的角色共计至多X张手牌（X为你的空置装备栏数），若其中有【闪】，"..
  "弃置之，然后获得其一张未以此法展示的牌。",

  ["#shanxi"] = "闪袭：展示你与一名角色至多%arg张手牌，弃置其中一张【闪】并获得对方一张未展示牌",
  ["#shanxi-prey"] = "闪袭：获得其中一张牌",

  ["$shanxi1"] = "敌援未到，需要速战速决！",
  ["$shanxi2"] = "快马加鞭，赶在敌人戒备之前！",
}

Fk:addPoxiMethod{
  name = "shanxi",
  card_filter = function(to_select, selected, data)
    return #selected < #Self:getAvailableEquipSlots()
  end,
  feasible = function(selected)
    return #selected > 0
  end,
}

Fk:addPoxiMethod{
  name = "shanxi_prey",
  prompt = "#shanxi-prey",
  card_filter = function(to_select, selected, data)
    return #selected == 0
  end,
  feasible = function(selected)
    return #selected == 1
  end,
}

shanxi:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player)
    return "#shanxi:::"..#player:getAvailableEquipSlots()
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(shanxi.name, Player.HistoryPhase) == 0 and #player:getAvailableEquipSlots() > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not to_select:inMyAttackRange(player) and to_select ~= player and
      not (player:isKongcheng() and to_select:isKongcheng())
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card_data, extra_data, visible_data = {}, {}, {}
    if not target:isKongcheng() then
      table.insert(card_data, {target.general, target:getCardIds("h")})
      for _, id in ipairs(target:getCardIds("h")) do
        if not player:cardVisible(id) then
          visible_data[tostring(id)] = false
        end
      end
      if next(visible_data) == nil then visible_data = nil end
      extra_data.visible_data = visible_data
    end
    if not player:isKongcheng() then
      table.insert(card_data, { player.general, player:getCardIds("h") })
    end
    if #card_data == 0 then return end
    local result = room:askToPoxi(player, {
      poxi_type = shanxi.name,
      data = card_data,
      cancelable = false,
      extra_data = extra_data,
    })
    local from_cards = table.filter(result, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #from_cards > 0 then
      player:showCards(from_cards)
    end
    local to_cards = table.filter(result, function(id)
      return table.contains(target:getCardIds("h"), id)
    end)
    if #to_cards > 0 then
      target:showCards(to_cards)
    end

    if not table.find(table.connect(from_cards, to_cards), function (id)
      return Fk:getCardById(id).trueName == "jink"
    end) then return end

    local moves = {}
    local to_throw1 = table.filter(from_cards, function(id)
      return Fk:getCardById(id).trueName == "jink" and not player:prohibitDiscard(id)
    end)
    if #to_throw1 > 0 then
      table.insert(moves, {
        from = player,
        ids = to_throw1,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = player,
        skillName = shanxi.name,
      })
    end
    local to_throw2 = table.filter(to_cards, function(id)
      return Fk:getCardById(id).trueName == "jink"
    end)
    if #to_throw2 > 0 then
      table.insert(moves, {
        from = target,
        ids = to_throw2,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = player,
        skillName = shanxi.name,
      })
    end
    if #moves > 0 then
      room:moveCards(table.unpack(moves))
    end
    if player.dead or target.dead then return end
    card_data, extra_data, visible_data = {}, {}, {}
    local nonshow = table.filter(target:getCardIds("h"), function(id)
      return not table.contains(to_cards, id)
    end)
    if #nonshow > 0 then
      table.insert(card_data, {"$Hand", nonshow})
      for _, id in ipairs(nonshow) do
        if not player:cardVisible(id) then
          visible_data[tostring(id)] = false
        end
      end
      if next(visible_data) == nil then visible_data = nil end
      extra_data.visible_data = visible_data
    end
    if #target:getCardIds("e") > 0 then
      table.insert(card_data, { "$Equip", target:getCardIds("e") })
    end
    if #card_data == 0 then return end
    result = room:askToPoxi(player, {
      poxi_type = "shanxi_prey",
      data = card_data,
      cancelable = false,
      extra_data = extra_data,
    })
    room:obtainCard(player, result, false, fk.ReasonPrey, player, shanxi.name)
  end,
})

return shanxi
