local buyi = fk.CreateSkill{
  name = "ol_ex__buyi",
}

Fk:loadTranslationTable{
  ["ol_ex__buyi"] = "补益",
  [":ol_ex__buyi"] = "当一名角色进入濒死状态时，你可以选择其一张牌，若此牌不为基本牌，其弃置此牌，然后回复1点体力。",

  ["#ol_ex__buyi-invoke"] = "补益：选择 %dest 的一张牌，若为非基本牌，其弃置之并回复1点体力",

  ["$ol_ex__buyi1"] = "补气凝神，百邪不侵。",
  ["$ol_ex__buyi2"] = "今植桑梧，可荫来者。",
}

buyi:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(buyi.name) and not target:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = buyi.name,
      prompt = "#ol_ex__buyi-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "he",
      skill_name = buyi.name,
    })
    if table.contains(target:getCardIds("h"), id) then
      target:showCards(id)
    end
    if target.dead then return end
    if Fk:getCardById(id).type ~= Card.TypeBasic then
      if not target:prohibitDiscard(id) then
        room:throwCard(id, buyi.name, target, target)
      end
      if not target.dead and target:isWounded() then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = buyi.name,
        }
      end
    end
  end,
})

return buyi
