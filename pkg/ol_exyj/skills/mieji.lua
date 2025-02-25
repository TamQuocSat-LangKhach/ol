local this = fk.CreateSkill{
  name = "ol_ex__mieji",
}

this:addEffect("active", {
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  prompt = "#ol_ex__mieji",
  can_use = function(self, player)
    return player:usedSkillTimes(this.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeTrick
  end,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    return #selected == 0 and to_select ~= Self.id and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCards({
      ids = effect.cards,
      from = player,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = this.name,
      moveVisible = true,
      drawPilePosition = 1,
    })
    local ids = room:askToDiscard(target, { min_num = 1, max_num = 1, include_equip = true, skill_name = this.name, cancelable = false, pattern = ".", prompt = "#ol_ex__mieji-discard1"})
    if #ids > 0 and Fk:getCardById(ids[1]).type ~= Card.TypeTrick and not target.dead then
      room:askToDiscard(target, { min_num = 1, max_num = 1, include_equip = true, skill_name = this.name, cancelable = false, pattern = ".", prompt = "#ol_ex__mieji-discard2"})
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__mieji"] = "灭计",
  [":ol_ex__mieji"] = "出牌阶段限一次，你可以将一张锦囊牌置于牌堆顶并令一名有手牌的其他角色选择一项：1.弃置一张锦囊牌；2.依次弃置两张牌。",
  
  ["#ol_ex__mieji"] = "灭计：将一张锦囊牌置于牌堆顶，令一名角色弃一张锦囊牌或弃置两张牌",
  ["#ol_ex__mieji-discard1"] = "灭计：请弃置一张锦囊牌，或依次弃置两张牌",
  ["#ol_ex__mieji-discard2"] = "灭计：请再弃置一张牌",
  
  ["$ol_ex__mieji1"] = "喝了这杯酒，别再理这世闻事。",
  ["$ol_ex__mieji2"] = "我欲借陛下性命一用。",
}

return this