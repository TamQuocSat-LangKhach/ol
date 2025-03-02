local skill = fk.CreateSkill {
  name = "#py_halberd_skill",
  attached_equip = "py_halberd",
}

Fk:loadTranslationTable{
  ["#py_halberd_skill"] = "无双方天戟",
  ["py_halberd_discard"] = "弃置%dest一张牌",
}

skill:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash" and not data.chain
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local all_choices = {"draw1", "py_halberd_discard::"..data.to.id, "Cancel"}
    local choices = table.simpleClone(all_choices)
    if data.to.dead or data.to:isNude() then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = skill.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "draw1" then
      player:drawCards(1, skill.name)
    else
      local card = room:askToChooseCard(player, {
        target = data.to,
        flag = "he",
        skill_name = skill.name,
      })
      room:throwCard(card, skill.name, data.to, player)
    end
  end,
})

return skill
