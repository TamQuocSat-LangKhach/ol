local this = fk.CreateSkill { 
  name = "ol_ex__huangtian_other&",
  anim_type = "support",
  prompt = "#ol_ex__huangtian-active",
  mute = true,
}

this:addEffect('active', {
  can_use = function(self, player)
    if player.kingdom ~= "qun" then return false end
    local targetRecorded = player:getTableMark("ol_ex__huangtian_sources-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill("ol_ex__huangtian") and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_num = 1,
  card_filter = function (self, player, to_select, selected)
    if #selected < 1 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip then
      local card = Fk:getCardById(to_select)
      return card.trueName == "jink" or card.suit == Card.Spade
    end
  end,
  target_num = 1,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    if #selected == 0 and to_select ~= Self.id and to_select:hasSkill("ol_ex__huangtian") then
      local targetRecorded = Self:getMark("ol_ex__huangtian_sources-phase")
      return type(targetRecorded) ~= "table" or not table.contains(targetRecorded, to_select)
    end
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:notifySkillInvoked(player, "ol_ex__huangtian")
    target:broadcastSkillInvoke("ol_ex__huangtian")
    room:addTableMarkIfNeed(player, "ol_ex__huangtian_sources-phase", target.id)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, this.name, nil, true)
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__huangtian_other&"] = "黄天",
  [":ol_ex__huangtian_other&"] = "出牌阶段限一次，你可将一张【闪】或♠手牌（正面朝上移动）交给张角。",
  
  ["#ol_ex__huangtian-active"] = "发动黄天，选择一张【闪】或♠手牌（正面朝上移动）交给一名拥有“黄天”的角色",
}

return this
