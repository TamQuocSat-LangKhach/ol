local tongpao = fk.CreateSkill{
  name = "qin__tongpao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__tongpao"] = "同袍",
  [":qin__tongpao"] = "锁定技，其他秦势力角色使用防具牌结算后，若你没有装备防具，你从游戏外使用一张相同的防具牌（离开装备区时销毁）。",

  ["$qin__tongpao"] = "岂曰无衣，与子同袍！"
}

tongpao:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(tongpao.name) and target ~= player and target.kingdom == "qin" and
      data.card.sub_type == Card.SubtypeArmor and #player:getEquipments(Card.SubtypeArmor) == 0 and
      player:canUseTo(data.card, player)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local armor = table.find(room.void, function(id)
      local card = Fk:getCardById(id)
      return card.name == data.card.name and card.suit == data.card.suit and card.number == data.card.number
    end) or room:printCard(data.card.name, data.card.suit, data.card.number).id
    room:setCardMark(Fk:getCardById(armor), MarkEnum.DestructOutEquip, 1)
    room:useCard{
      from = player,
      tos = {player},
      card = Fk:getCardById(armor),
    }
  end
})

return tongpao
