local xianying = fk.CreateSkill{
  name = "xianying",
}

Fk:loadTranslationTable{
  ["xianying"] = "贤膺",
  [":xianying"] = "准备阶段或当你受到伤害后，你可以摸两张牌并弃置任意张牌（不能是本轮以此法弃置过的张数），若弃置牌同名，你可以于本回合结束时"..
  "视为使用之。",

  ["xianying_active"] = "贤膺",
  ["#xianying-discard"] = "贤膺：弃置任意张牌（本轮未弃置过的张数），若牌名均相同则本回合结束可以视为使用之",
  ["#xianying-use"] = "贤膺：你可以视为使用这些牌",

  ["$xianying1"] = "古之贤良，不以一己之得失论成败。",
  ["$xianying2"] = "朗感亚父大恩，纵百死亦衔环相报。",
}

local xianying_spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, xianying.name)
    if player.dead then return end
    if player:isNude() then
      room:addTableMark(player, "xianying_num-round", 0)
      return
    end
    local cards = table.filter(player:getCardIds("he"), function (id)
      return not player:prohibitDiscard(id)
    end)
    local available_nums = {}
    for i = 0, #cards, 1 do
      if not table.contains(player:getTableMark("xianying_num-round"), i) then
        table.insert(available_nums, i)
      end
    end
    if #available_nums == 0 then
      room:addTableMark(player, "xianying_num-round", 0)
      return
    end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "xianying_active",
      prompt = "#xianying-discard",
      cancelable = false,
      extra_data = {
        available_nums = available_nums,
      }
    })
    if not (success and dat) then
      dat = {}
      dat.cards = table.random(cards, table.random(available_nums))
    end
    room:addTableMark(player, "xianying_num-round", #dat.cards)
    if #dat.cards > 0 then
      if table.every(dat.cards, function (id)
        return Fk:getCardById(id).trueName == Fk:getCardById(dat.cards[1]).trueName
      end) then
        local name = Fk:getCardById(dat.cards[1]).trueName
        if Fk:cloneCard(name).type == Card.TypeBasic or Fk:cloneCard(name):isCommonTrick() then
          room:addTableMark(player, "xianying-turn", name)
        end
      end
      room:throwCard(dat.cards, xianying.name, player, player)
    end
  end,
}

xianying:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xianying.name) and player.phase == Player.Start
  end,
  on_use = xianying_spec.on_use,
})
xianying:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xianying.name)
  end,
  on_use = xianying_spec.on_use,
})

xianying:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:getMark("xianying-turn") ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local banner = room:getBanner(xianying.name) or {}
    local cards = {}
    for _, name in ipairs(player:getTableMark("xianying-turn")) do
      local c
      local card = table.filter(banner, function (id)
        return Fk:getCardById(id).name == name and room:getCardArea(id) == Card.Void and not table.contains(cards, id)
      end)
      if #card > 0 then
        c = card[1]
      else
        c = room:printCard(name).id
        table.insert(banner, c)
      end
      table.insert(cards, c)
    end
    room:setBanner(xianying.name, banner)
    while #cards > 0 and not player.dead do
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = xianying.name,
        prompt = "#xianying-use",
        extra_data = {
          bypass_times = true,
          expand_pile = cards,
        },
        skip = true,
      })
      if use then
        table.removeOne(cards, use.card.id)
        local card = Fk:cloneCard(use.card.name)
        card.skillName = xianying.name
        use = {
          card = card,
          from = player,
          tos = use.tos,
          extraUse = true,
        }
        room:useCard(use)
      else
        return
      end
    end
  end,
})

return xianying
