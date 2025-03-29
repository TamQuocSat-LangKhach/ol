local jiaodi = fk.CreateSkill{
  name = "jiaodi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiaodi"] = "剿狄",
  [":jiaodi"] = "锁定技，你的攻击范围始终等于你的当前体力值。当你使用【杀】指定唯一目标时，若目标的攻击范围不大于你，你令此【杀】伤害+1，"..
  "然后获得该角色一张手牌；若目标的攻击范围不小于你，你弃置该角色区域内一张牌，选择一名角色成为此【杀】的额外目标。",

  ["#jiaodi-prey"] = "剿狄：获得 %dest 一张手牌",
  ["#jiaodi-discard"] = "剿狄：弃置 %dest 区域内一张牌",
  ["#jiaodi-choose"] = "剿狄：选择一名角色成为此%arg额外目标",
}

jiaodi:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiaodi.name) and
      data.card.trueName == "slash" and data:isOnlyTarget(data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    if player:getAttackRange() >= to:getAttackRange() then
      data.additionalDamage = (data.additionalDamage or 0) + 1
      if not to:isKongcheng() then
        local card = room:askToChooseCard(player, {
          target = to,
          flag = "h",
          skill_name = jiaodi.name,
          prompt = "#jiaodi-prey::"..to.id,
        })
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, jiaodi.name, nil, false, player)
        if player.dead or to.dead then return end
      end
    end
    if player:getAttackRange() <= to:getAttackRange() then
      if not to:isAllNude() then
        local card = room:askToChooseCard(player, {
          target = to,
          flag = "hej",
          skill_name = jiaodi.name,
          prompt = "#jiaodi-discard::"..to.id,
        })
        room:throwCard(card, jiaodi.name, to, player)
        if player.dead then return end
      end
      if #data:getExtraTargets() > 0 then
        local tos = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = data:getExtraTargets(),
          skill_name = jiaodi.name,
          prompt = "#jiaodi-choose:::"..data.card:toLogString(),
          cancelable = false,
        })
        data:addTarget(tos[1])
      end
    end
  end,
})
jiaodi:addEffect("atkrange", {
  final_func = function (self, player)
    if player:hasSkill(jiaodi.name) then
      return player.hp
    end
  end,
})

return jiaodi
