local bingyi = fk.CreateSkill{
  name = "ol__bingyi",
}

Fk:loadTranslationTable{
  ["ol__bingyi"] = "秉壹",
  [":ol__bingyi"] = "每阶段限一次，当你的牌被弃置后，你可以展示所有手牌，若颜色均相同，你可以与至多X名其他角色各摸一张牌（X为你的手牌数）。",

  ["#ol__bingyi-choose"] = "秉壹：你可以与至多%arg名其他角色各摸一张牌，点“取消”仅自己摸牌",

  ["$ol__bingyi1"] = "秉直进谏，勿藏私心！",
  ["$ol__bingyi2"] = "秉公守一，不负圣恩！",
}

bingyi:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(bingyi.name) and player:usedSkillTimes(bingyi.name, Player.HistoryPhase) == 0 and not player:isKongcheng() then
      local phase_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
      if phase_event == nil then return false end
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(player:getCardIds("h"))
    player:showCards(cards)
    if table.find(cards, function (id)
      return Fk:getCardById(id).color == Card.NoColor or Fk:getCardById(id).color ~= Fk:getCardById(cards[1]).color
    end) then
      return
    end
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = #cards,
      targets = room:getOtherPlayers(player, false),
      skill_name = bingyi.name,
      prompt = "#ol__bingyi-choose:::"..#cards,
      cancelable = true,
    })
    table.insert(tos, player)
    room:sortByAction(tos)
    for _, p in ipairs(tos) do
      if not p.dead then
        p:drawCards(1, bingyi.name)
      end
    end
  end,
})

return bingyi
