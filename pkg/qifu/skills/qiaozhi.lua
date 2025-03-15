local qiaozhi = fk.CreateSkill{
  name = "qiaozhi",
}

Fk:loadTranslationTable{
  ["qiaozhi"] = "巧织",
  [":qiaozhi"] = "出牌阶段，你可以弃置一张牌，亮出牌堆顶的两张牌，获得其中的一张牌。此技能于你以此法得到的牌从你的手牌区离开之前无效。",

  ["@@qiaozhi-inhand"] = "巧织",
  ["#qiaozhi"] = "巧织：弃置一张牌，亮出牌堆顶两张牌并获得其中一张",
  ["#qiaozhi-choose"] = "巧织：选择要获得的一张牌",

  ["$qiaozhi1"] = "皓齿断银丝，轻吻公子衣上雪。",
  ["$qiaozhi2"] = "玉指拈锦线，今日织君身上衣。",
}

qiaozhi:addEffect("active", {
  prompt = "#qiaozhi",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, qiaozhi.name, player, player)
    if player.dead then return end
    local cards = room:getNCards(2)
    room:turnOverCardsFromDrawPile(player, cards, qiaozhi.name)
    local id = room:askToChooseCard(player, {
      target = player,
      flag = {
        card_data = { { qiaozhi.name, cards } }
      },
      skill_name = qiaozhi.name,
      prompt = "#qiaozhi-choose",
    })
    room:obtainCard(player, id, true, fk.ReasonJustMove, player, qiaozhi.name, "@@qiaozhi-inhand")
    room:cleanProcessingArea(cards, qiaozhi.name)
  end,
})
qiaozhi:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return skill.name == qiaozhi.name and
      table.find(from:getCardIds("h"), function (id)
        return Fk:getCardById(id, true):getMark("@@qiaozhi-inhand") > 0
      end)
  end,
})

return qiaozhi
