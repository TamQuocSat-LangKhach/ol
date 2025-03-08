local xiaosi = fk.CreateSkill{
  name = "xiaosi",
}

Fk:loadTranslationTable{
  ["xiaosi"] = "效死",
  [":xiaosi"] = "出牌阶段限一次，你可以弃置一张基本牌并选择一名有手牌的其他角色，其弃置一张基本牌（若其不能弃置则你摸一张牌），"..
  "然后你可以使用这些牌（无距离和次数限制）。",

  ["#xiaosi"] = "效死：弃一张基本牌，令另一名角色弃一张基本牌，然后你可以使用这些牌",
  ["#xiaosi-discard"] = "效死：请弃置一张基本牌，%src 可以使用之",
  ["#xiaosi-use"] = "效死：你可以使用这些牌（无距离次数限制）",

  ["$xiaosi1"] = "既抱必死之心，焉存偷生之意。",
  ["$xiaosi2"] = "为国效死，死得其所。",
}

xiaosi:addEffect("active", {
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#xiaosi",
  can_use = function(self, player)
    return player:usedSkillTimes(xiaosi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = {}
    table.insert(cards, effect.cards[1])
    room:throwCard(effect.cards, xiaosi.name, player, player)
    if not target.dead then
      local card = room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = xiaosi.name,
        pattern = ".|.|.|.|.|basic",
        prompt = "#xiaosi-discard:"..player.id,
        cancelable = false,
        skip = true,
      })
      if #card > 0 then
        table.insert(cards, card[1])
        room:throwCard(card, xiaosi.name, target, target)
      else
        if player.dead then return end
        player:drawCards(1, xiaosi.name)
      end
    end
    while not player.dead do
      cards = table.filter(cards, function (id)
        return table.contains(room.discard_pile, id)
      end)
      if #cards == 0 then return false end
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = xiaosi.name,
        prompt = "#xiaosi-use",
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          extraUse = true,
          expand_pile = cards,
        },
        skip = true,
      })
      if use then
        table.removeOne(cards, use.card:getEffectiveId())
        room:useCard(use)
      else
        break
      end
    end
  end,
})

return xiaosi
