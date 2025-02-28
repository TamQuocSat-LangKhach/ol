local ninge = fk.CreateSkill{
  name = "ninge",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ninge"] = "狞恶",
  [":ninge"] = "锁定技，当一名角色于当前回合内第二次受到伤害后，若其为你或来源为你，你摸一张牌，弃置其场上一张牌。",

  ["$ninge1"] = "古之恶来，今之典韦！",
  ["$ninge2"] = "宁为刀俎，不为鱼肉！",
}

ninge:addEffect(fk.Damaged, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ninge.name) and (target == player or data.from == player) then
      local events = player.room.logic:getActualDamageEvents(2, function(e) return e.data.to == target end)
      return #events > 1 and events[2].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, { target })
    player:drawCards(1, ninge.name)
    if not player.dead and not target.dead and #target:getCardIds("ej") > 0 then
      local id = room:askToChooseCard(player, {
        target = target,
        flag = "ej",
        skill_name = ninge.name,
      })
      room:throwCard(id, ninge.name, target, player)
    end
  end,
})

return ninge