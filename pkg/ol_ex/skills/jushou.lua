local jushou = fk.CreateSkill{
  name = "ol_ex__jushou",
}

Fk:loadTranslationTable{
  ["ol_ex__jushou"] = "据守",
  [":ol_ex__jushou"] = "结束阶段，你可以翻面，摸四张牌，然后选择一项：1.使用一张装备牌手牌；2.弃置一张非装备牌手牌。",

  ["#ol_ex__jushou-ask"] = "据守：使用手牌中的一张装备牌，或弃置手牌中的一张非装备牌",

  ["$ol_ex__jushou1"] = "兵精粮足，守土一方。",
  ["$ol_ex__jushou2"] = "坚守此地，不退半步。",
}

jushou:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jushou.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:turnOver()
    if player.dead then return false end
    player:drawCards(4, jushou.name)
    if player.dead or player:isKongcheng() then return false end
    local cards = table.filter(player:getCardIds("h"), function (id)
      local card = Fk:getCardById(id)
      return (card.type == Card.TypeEquip and player:canUseTo(card, player)) or
        (card.type ~= Card.TypeEquip and not player:prohibitDiscard(card))
    end)
    if #cards == 0 then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = jushou.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#ol_ex__jushou-ask",
      cancelable = false,
    })
    card = Fk:getCardById(card[1])
    if card.type == Card.TypeEquip then
      room:useCard({
        from = player,
        tos = {player},
        card = card,
      })
    else
      room:throwCard(card, jushou.name, player, player)
    end
  end,
})

return jushou