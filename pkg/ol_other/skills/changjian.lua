local changjian = fk.CreateSkill{
  name = "qin__changjian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__changjian"] = "长剑",
  [":qin__changjian"] = "锁定技，你的攻击范围+1；当你使用【杀】指定目标时，选择一项：1.令攻击范围内的一名角色成为此【杀】的额外目标；"..
  "2.令此【杀】造成的伤害+1。",

  ["qin__changjian_target"] = "令此【杀】额外指定一个目标",
  ["qin__changjian_damage"] = "令此【杀】伤害+1",
  ["#qin__changjian-choose"] = "长剑：令一名角色成为此【杀】的额外目标",

  ["$qin__changjian"] = "长剑一出，所向披靡！",
}

changjian:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(changjian.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"qin__changjian_damage"}
    if #data:getExtraTargets() > 0 then
      table.insert(choices, 1, "qin__changjian_target")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = changjian.name,
    })
    if choice == "qin__changjian_target" then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = data:getExtraTargets(),
        skill_name = changjian.name,
        prompt = "#qin__changjian-choose",
        cancelable = false,
      })[1]
      data:addTarget(to)
    else
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})
changjian:addEffect("atkrange", {
  correct_func = function (self, from, to)
    if from:hasSkill(changjian.name) then
      return 1
    end
  end,
})

return changjian
