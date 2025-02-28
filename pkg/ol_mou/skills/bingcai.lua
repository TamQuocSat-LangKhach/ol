local bingcai = fk.CreateSkill{
  name = "bingcai",
}

Fk:loadTranslationTable{
  ["bingcai"] = "并才",
  [":bingcai"] = "每回合第一张基本牌被使用时，你可以重铸一张锦囊牌。若这两张牌均为伤害类或非伤害类，则此牌额外结算一次。",

  ["#bingcai1-invoke"] = "并才：是否重铸一张锦囊牌？若为伤害类，此%arg额外结算一次",
  ["#bingcai2-invoke"] = "并才：是否重铸一张锦囊牌？若不为伤害类，此%arg额外结算一次",
}

bingcai:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(bingcai.name) and data.card.type == Card.TypeBasic and not player:isKongcheng() then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.card.type == Card.TypeBasic
      end, Player.HistoryTurn)
      return #events == 1 and events[1] == player.room.logic:getCurrentEvent()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local i = data.card.is_damage_card and 1 or 2
    local card = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = bingcai.name,
      cancelable = true,
      pattern = ".|.|.|.|.|trick",
      prompt = "#bingcai"..i.."-invoke:::"..data.card:toLogString(),
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(event:getCostData(self).cards[1])
    room:recastCard(event:getCostData(self).cards, player, bingcai.name)
    if (card.is_damage_card and data.card.is_damage_card) or
      (not card.is_damage_card and not data.card.is_damage_card) then
      data.additionalEffect = (data.additionalEffect or 0) + 1
    end
  end,
})

return bingcai
