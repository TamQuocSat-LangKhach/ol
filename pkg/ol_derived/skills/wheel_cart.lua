local skill = fk.CreateSkill {
  name = "#wheel_cart_skill",
  attached_equip = "wheel_cart",
}

Fk:loadTranslationTable{
  ["#wheel_cart_skill"] = "飞轮战舆",
  ["#wheel_cart-invoke"] = "飞轮战舆：你可以令 %dest 交给你一张牌，然后弃置此牌",
  ["#wheel_cart-give"] = "飞轮战舆：你须交给 %src 一张牌",
}

skill:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(skill.name) and not target.dead and not target:isNude() and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard,1, function(e)
        local use = e.data
        return use.from == target and use.card.type ~= Card.TypeBasic
      end, Player.HistoryTurn) > 0 and
      table.find(player:getEquipments(Card.SubtypeTreasure), function(id)
        return Fk:getCardById(id).name == "wheel_cart"
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#wheel_cart-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = skill.name,
      prompt = "#wheel_cart-give:"..player.id,
      cancelable = false,
    })
    room:obtainCard(player, card, false, fk.ReasonGive, target, skill.name)
    if player.dead then return end
    local throw = table.filter(player:getEquipments(Card.SubtypeTreasure), function(id)
      return Fk:getCardById(id).name == "wheel_cart"
    end)
    if #throw > 0 then
      room:throwCard(throw, skill.name, player, player)
    end
  end,
})

return skill
