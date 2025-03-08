local mubing = fk.CreateSkill{
  name = "mubing",
}

Fk:loadTranslationTable{
  ["mubing"] = "募兵",
  [":mubing"] = "出牌阶段开始时，你可以亮出牌堆顶三张牌，然后你可以弃置任意张手牌，获得任意张亮出的牌，你弃置牌点数之和不能小于获得牌点数之和。",

  ["mubing_prey"] = "募兵",
  ["#mubing-discard"] = "募兵：弃置任意张手牌，获得点数之和不大于你弃牌点数之和的牌",
  ["@mubing"] = "募兵",
  ["#mubing-give"] = "募兵：你可以将这些牌分配给任意角色，点“取消”自己保留",

  ["$mubing1"] = "兵者，不唯在精，亦在广。",
  ["$mubing2"] = "男儿当从军，功名马上取。",
}

Fk:addPoxiMethod{
  name = "mubing",
  prompt = "#mubing-discard",
  card_filter = function(to_select, selected, data)
    if table.contains(data[2][2], to_select) and Self:prohibitDiscard(to_select) then return false end
    if table.contains(data[2][2], to_select) then
      return true
    else
      local count = 0
      for _, id in ipairs(selected) do
        local num = Fk:getCardById(id).number
        if table.contains(data[1][2], id) then
          count = count - num
        else
          count = count + num
        end
      end
      return count >= Fk:getCardById(to_select).number
    end
  end,
  feasible = function(selected, data)
    if not data or #selected == 0 then return false end
    local count = 0
    for _, id in ipairs(selected) do
      local num = Fk:getCardById(id).number
      if table.contains(data[1][2], id) then
        count = count - num
      else
        count = count + num
      end
    end
    return count >= 0
  end,
}
mubing:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mubing.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(player:usedSkillTimes("diaoling", Player.HistoryGame) > 0 and 4 or 3)
    room:turnOverCardsFromDrawPile(player, cards, mubing.name)
    if not player:isKongcheng() then
      local result = room:askToPoxi(player, {
        poxi_type = mubing.name,
        data = {
          { "prey", cards },
          { "hand_card", player:getCardIds("h") },
        },
        cancelable = true,
      })
      local get, throw = {}, {}
      for _, id in ipairs(result) do
        if table.contains(cards, id) then
          table.insert(get, id)
        else
          table.insert(throw, id)
        end
      end
      if #throw > 0 then
        room:throwCard(throw, mubing.name, player, player)
      end
      if #get > 0 and not player.dead then
        if player:usedSkillTimes("diaoling", Player.HistoryGame) == 0 then
          for _, id in ipairs(get) do
            local card = Fk:getCardById(id)
            if card.trueName == "slash" or card.sub_type == Card.SubtypeWeapon or
              (card.is_damage_card and card.type == Card.TypeTrick) then
              room:addPlayerMark(player, "@mubing")
            end
          end
        end
        room:obtainCard(player, get, true, fk.ReasonJustMove, player, mubing.name)
        if player:usedSkillTimes("diaoling", Player.HistoryGame) > 0 and not player.dead then
          get = table.filter(get, function(id)
            return table.contains(player:getCardIds("h"), id)
          end)
          if #get > 0 then
            room:askToYiji(player, {
              cards = get,
              targets = room.alive_players,
              skill_name = mubing.name,
              min_num = 0,
              max_num = 4,
              prompt = "#mubing-give",
            })
          end
        end
      end
    end
    room:cleanProcessingArea(cards)
  end,
})

return mubing
