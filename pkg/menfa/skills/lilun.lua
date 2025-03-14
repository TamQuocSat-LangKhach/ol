local lilun = fk.CreateSkill{
  name = "lilun",
}

Fk:loadTranslationTable{
  ["lilun"] = "离论",
  [":lilun"] = "出牌阶段限一次，你可以重铸两张牌名相同的牌（不能是本回合以此法重铸过的牌名）并可以使用其中一张牌。",

  ["#lilun"] = "离论：重铸两张牌名相同的牌，然后可以使用其中一张",
  ["#lilun-use"] = "离论：你可以使用其中一张牌",

  ["$lilun1"] = "",
  ["$lilun2"] = "",
}

lilun.zhongliu_type = Player.HistoryPhase

lilun:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#lilun",
  card_num = 2,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(lilun.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 1 then return false end
    local card_name = Fk:getCardById(to_select).trueName
    return not table.contains(player:getTableMark("lilun-turn"), card_name) and
      (#selected == 0 or card_name == Fk:getCardById(selected[1]).trueName)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:addTableMark(player, "lilun-turn", Fk:getCardById(effect.cards[1]).trueName)
    room:recastCard(effect.cards, player, lilun.name)
    if player.dead then return end
    local cards = table.filter(effect.cards, function (id)
      return table.contains(room.discard_pile, id) and player:canUse(Fk:getCardById(id), {bypass_times = true})
    end)
    if #cards == 0 then return end
    room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = lilun.name,
      prompt = "#lilun-use",
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = cards,
      }
    })
  end
})

return lilun
