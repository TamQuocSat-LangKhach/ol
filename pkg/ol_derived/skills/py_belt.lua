local skill = fk.CreateSkill {
  name = "#py_belt_skill",
  attached_equip = "py_belt",
}

Fk:loadTranslationTable{
  ["#py_belt_skill"] = "玲珑狮蛮带",
}

skill:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.from ~= player and #data.use.tos == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = skill.name,
      pattern = ".|.|heart",
    }
    room:judge(judge)
    if judge:matchPattern() then
      table.insertIfNeed(data.use.nullifiedTargets, player)
    end
  end,
})

return skill
