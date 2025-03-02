local skill = fk.CreateSkill {
  name = "#grain_cart_skill",
  attached_equip = "grain_cart",
}

Fk:loadTranslationTable{
  ["#grain_cart_skill"] = "四乘粮舆",
  ["#grain_cart-invoke"] = "四乘粮舆：你可以摸两张牌，然后弃置此牌",
}

skill:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and player:getHandcardNum() < player.hp and
      table.find(player:getEquipments(Card.SubtypeTreasure), function(id)
        return Fk:getCardById(id).name == "grain_cart"
      end)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#grain_cart-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, skill.name)
    local throw = table.filter(player:getEquipments(Card.SubtypeTreasure), function(id)
      return Fk:getCardById(id).name == "grain_cart"
    end)
    if player.dead then return end
    if #throw > 0 then
      room:throwCard(throw, skill.name, player, player)
    end
  end,
})

return skill
