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
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "qin_seal_viewas",
      prompt = "#qin_seal-use",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard(event:getCostData(self).choice)
    card.skillName = skill.name
    room:useCard{
      from = player,
      tos = {},
      card = card,
    }
  end,
})

return skill
