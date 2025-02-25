local this = fk.CreateSkill{ name = "ol_ex__jushou" }

this:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(this.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:turnOver()
    if player.dead then return false end
    room:drawCards(player, 4, this.name)
    if player.dead then return false end
    local jushou_card
    for _, id in pairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeEquip and not player:prohibitUse(card)) or (card.type ~= Card.TypeEquip and not player:prohibitDiscard(card)) then
        jushou_card = card
        break
      end
    end
    if not jushou_card then return end
    local _, ret = room:askToUseActiveSkill(player, { skill_name = "#ol_ex__jushou_select", prompt = "#ol_ex__jushou-select", cancelable = false})
    if ret then
      jushou_card = Fk:getCardById(ret.cards[1])
    end
    if jushou_card then
      if jushou_card.type == Card.TypeEquip then
        room:useCard({
          from = player.id,
          tos = {player},
          card = jushou_card,
        })
      else
        local id = jushou_card:getEffectiveId()
        if id then
          room:throwCard(id, this.name, player, player)
        end
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__jushou"] = "据守",
  [":ol_ex__jushou"] = "结束阶段，你可翻面，你摸四张牌，选择：1.使用一张为装备牌的手牌；2.弃置一张不为装备牌的手牌。",

  ["#ol_ex__jushou_select"] = "据守",
  ["#ol_ex__jushou-select"] = "据守：选择使用手牌中的一张装备牌或弃置手牌中的一张非装备牌",

  ["$ol_ex__jushou1"] = "兵精粮足，守土一方。",
  ["$ol_ex__jushou2"] = "坚守此地，不退半步。",
}

return this