local skill = fk.CreateSkill {
  name = "#rhino_comb_skill",
  attached_equip = "rhino_comb",
}

Fk:loadTranslationTable{
  ["#rhino_comb_skill"] = "犀梳",
  ["rhino_comb_judge"] = "跳过判定阶段",
  ["rhino_comb_discard"] = "跳过弃牌阶段",
}

skill:addEffect(fk.EventPhaseChanging, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.phase == Player.Judge and
      not (data.skipped and player.skipped_phases[Player.Discard])
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if not player.skipped_phases[Player.Discard] then
      table.insert(choices, 1, "rhino_comb_discard")
    end
    if not data.skipped then
      table.insert(choices, 1, "rhino_comb_judge")
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
    player:broadcastSkillInvoke("zhuangshu", 4)
    if event:getCostData(self).choice == "rhino_comb_judge" then
      data.skipped = true
    else
      player:skip(Player.Discard)
    end
  end,
})

return skill
