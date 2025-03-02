local skill = fk.CreateSkill {
  name = "#jade_comb_skill",
  attached_equip = "jade_comb",
}

Fk:loadTranslationTable{
  ["#jade_comb_skill"] = "琼梳",
  ["#jade_comb-invoke"] = "琼梳：你可以弃置%arg张牌，防止你受到的伤害",
}

skill:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      #player:getCardIds("he") > data.damage
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, id in ipairs(player:getCardIds("he")) do
      if not player:prohibitDiscard(id) and
        not (table.contains(player:getEquipments(Card.SubtypeTreasure), id) and Fk:getCardById(id).name == skill.attached_equip) then
        table.insert(cards, id)
      end
    end
    cards = room:askToDiscard(player, {
      min_num = data.damage,
      max_num = data.damage,
      include_equip = true,
      skill_name = skill.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#jade_comb-invoke:::"..data.damage,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("zhuangshu", 3)
    data:preventDamage()
    player.room:throwCard(event:getCostData(self).cards, skill.name, player, player)
  end,
})

return skill
