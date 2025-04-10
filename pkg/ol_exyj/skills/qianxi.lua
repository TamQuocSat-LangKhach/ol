local qianxi = fk.CreateSkill {
  name = "ol_ex__qianxi",
}

Fk:loadTranslationTable{
  ["ol_ex__qianxi"] = "潜袭",
  [":ol_ex__qianxi"] = "准备阶段，你可以摸一张牌并展示一张手牌。若如此做，你距离为1的其他角色本回合不能使用或打出与“潜袭”牌颜色相同的手牌，"..
  "你本回合使用“潜袭”牌伤害基数值+1。",

  ["#ol_ex__qianxi-show"] = "潜袭：展示一张手牌，本回合此牌伤害+1，距离1的角色不能使用打出此颜色手牌",
  ["@ol_ex__qianxi-turn"] = "潜袭",
  ["@@ol_ex__qianxi-inhand-turn"] = "潜袭",
}

qianxi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qianxi.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, qianxi.name)
    if player.dead or player:isKongcheng() then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = qianxi.name,
      prompt = "#ol_ex__qianxi-show",
      cancelable = false,
    })
    local color = Fk:getCardById(card[1]):getColorString()
    room:setCardMark(Fk:getCardById(card[1]), "@@ol_ex__qianxi-inhand-turn", 1)
    room:showCards(card, player)
    if player.dead or color == "nocolor" then return end
    for _, p in ipairs(room.alive_players) do
      if player:distanceTo(p) == 1 then
        room:doIndicate(player, {p})
        room:addTableMarkIfNeed(p, "@ol_ex__qianxi-turn", color)
      end
    end
  end,
})

qianxi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if table.contains(player:getTableMark("@ol_ex__qianxi-turn"), card:getColorString()) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and
        table.every(subcards, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
  prohibit_response = function(self, player, card)
    if table.contains(player:getTableMark("@ol_ex__qianxi-turn"), card:getColorString()) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and
        table.every(subcards, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
})

qianxi:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    if target == player and data.card.is_damage_card then
      local ids = Card:getIdList(data.card)
      return #ids == 1 and Fk:getCardById(ids[1]):getMark("@@ol_ex__qianxi-inhand-turn") > 0
    end
  end,
  on_refresh = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

return qianxi
