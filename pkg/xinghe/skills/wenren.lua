local wenren = fk.CreateSkill{
  name = "wenren",
}

Fk:loadTranslationTable{
  ["wenren"] = "温仁",
  [":wenren"] = "出牌阶段限一次，你可以选择任意名角色，其每满足一项便摸一张牌：1.没有手牌；2.手牌数不大于你。",

  ["#wenren"] = "温仁：令任意名手牌数不大于你的角色摸牌",
  ["#wenren_tip"] = "摸%arg张牌",

  ["$wenren1"] = "徐州地方千里，足壮玄德羽翼。",
  ["$wenren2"] = "自古举贤以仁，玄德当仁不让。",
}

wenren:addEffect("active", {
  anim_type = "support",
  prompt = "#wenren",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(wenren.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.TrueFunc,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    local n = 0
    if to_select:getHandcardNum() <= player:getHandcardNum() then
      n = 1
    end
    if to_select:isKongcheng() then
      n = n + 1
    end
    return "#wenren_tip:::"..n
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    local info = table.map(effect.tos, function (p)
      local n = 0
      if p:getHandcardNum() <= player:getHandcardNum() then
        n = 1
      end
      if p:isKongcheng() then
        n = n + 1
      end
      return n
    end)
    for i = 1, #effect.tos, 1 do
      local p = effect.tos[i]
      if not p.dead and info[i] > 0 then
        p:drawCards(info[i], wenren.name)
      end
    end
  end,
})

return wenren
