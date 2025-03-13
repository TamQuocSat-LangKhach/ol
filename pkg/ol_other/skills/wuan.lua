local wuan = fk.CreateSkill{
  name = "qin__wuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__wuan"] = "武安",
  [":qin__wuan"] = "锁定技，秦势力角色出牌阶段使用【杀】的次数上限+1，使用【杀】造成的伤害+1。",

  ["$qin__wuan"] = "受封武安，为国尽忠！",
}

wuan:addEffect(fk.AfterCardUseDeclared, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(wuan.name) and target.kingdom == "qin" and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})
wuan:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if player.kingdom == "qin" and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return #table.filter(Fk:currentRoom().alive_players, function(p)
        return p:hasSkill(wuan.name)
      end)
    end
  end,
})

return wuan
