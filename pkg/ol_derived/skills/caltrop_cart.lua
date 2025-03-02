local skill = fk.CreateSkill {
  name = "#caltrop_cart_skill",
  attached_equip = "caltrop_cart",
}

Fk:loadTranslationTable{
  ["#caltrop_cart_skill"] = "铁蒺玄舆",
  ["#caltrop_cart-invoke"] = "铁蒺玄舆：你可以令 %dest 弃置两张牌，然后弃置此牌",
}

skill:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(skill.name) and not target.dead and not target:isNude() and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == target
      end) == 0 and
      table.find(player:getEquipments(Card.SubtypeTreasure), function(id)
        return Fk:getCardById(id).name == "caltrop_cart"
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#caltrop_cart-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToDiscard(target, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = skill.name,
      cancelable = false,
    })
    if player.dead then return end
    local throw = table.filter(player:getEquipments(Card.SubtypeTreasure), function(id)
      return Fk:getCardById(id).name == "caltrop_cart"
    end)
    if #throw > 0 then
      room:throwCard(throw, skill.name, player, player)
    end
  end,
})

return skill
