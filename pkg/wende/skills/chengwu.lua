local chengwu = fk.CreateSkill{
  name = "chengwu",
  tags = { Skill.Lord, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chengwu"] = "成务",
  [":chengwu"] = "主公技，锁定技，其他晋势力角色攻击范围内的角色均视为在你的攻击范围内。",

  ["$chengwu1"] = "令行禁止，政通无虞。",
  ["$chengwu2"] = "上下一体，大业可筹。",
}

chengwu:addEffect("atkrange", {
  within_func = function (self, from, to)
    if from:hasSkill(chengwu.name) then
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.kingdom == "jin" and from ~= p and p:inMyAttackRange(to) then
          return true
        end
      end
    end
  end,
})

return chengwu
