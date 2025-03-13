local weiyang = fk.CreateSkill{
  name = "shengxiao_weiyang",
}

Fk:loadTranslationTable{
  ["shengxiao_weiyang"] = "未羊",
  [":shengxiao_weiyang"] = "出牌阶段限一次，你可以弃置一张牌（需与你以此法弃置过的类别均不同），然后回复1点体力。",

  ["#shengxiao_weiyang"] = "未羊：弃置一张牌（需与弃置过的类别不同），回复1点体力",
}

weiyang:addEffect("active", {
  anim_type = "support",
  prompt = "#shengxiao_weiyang",
  max_phase_use_time = 1,
  card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not table.contains(player:getTableMark(weiyang.name), Fk:getCardById(to_select).type) and
      not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:addTableMark(player, weiyang.name, Fk:getCardById(effect.cards[1]).type)
    room:throwCard(effect.cards, weiyang.name, player, player)
    if player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = weiyang.name,
      }
    end
  end,
})

return weiyang
