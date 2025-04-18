local skill = fk.CreateSkill {
  name = "#qin_seal_skill",
  attached_equip = "qin_seal",
}

Fk:loadTranslationTable{
  ["#qin_seal_skill"] = "传国玉玺",
  ["#qin_seal-use"] = "传国玉玺：你可以视为使用一种锦囊牌",
}

skill:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = {"savage_assault", "archery_attack", "god_salvation", "amazing_grace"},
      skill_name = skill.name,
      prompt = "#qin_seal-use",
      cancelable = true,
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

return skill
