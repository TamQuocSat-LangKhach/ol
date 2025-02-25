local this = fk.CreateSkill{
  name = "ol_ex__ninge",
}

this:addEffect(fk.Damaged, {
  anim_type = "control",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(this.name) and (target == player or data.from == player) then
      local events = player.room.logic:getActualDamageEvents(2, function(e) return e.data[1].to == target end)
      return #events > 1 and events[2].data[1] == data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, { target.id })
    player:drawCards(1, this.name)
    if not player.dead and not target.dead and #target:getCardIds{Player.Judge, Player.Equip} > 0 then
      local id = room:askToChooseCard(player, { target = target, flag = "ej", skill_name = this.name})
      room:throwCard({id}, this.name, target, player)
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__ninge"] = "狞恶",
  [":ol_ex__ninge"] = "锁定技，当一名角色于当前回合内第二次受到伤害后，若其为你或来源为你，你摸一张牌，弃置其装备区或判定区里的一张牌。",

  ["$ol_ex__ninge1"] = "古之恶来，今之典韦！",
  ["$ol_ex__ninge2"] = "宁为刀俎，不为鱼肉！",
}

return this