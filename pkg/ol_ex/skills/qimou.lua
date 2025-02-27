local qimou = fk.CreateSkill{
  name = "ol_ex__qimou",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["ol_ex__qimou"] = "奇谋",
  [":ol_ex__qimou"] = "限定技，出牌阶段，你可以失去X点体力，摸X张牌，本回合内与其他角色计算距离-X且可以多使用X张杀。",

  ["@qimou-turn"] = "奇谋",
  ["#ol_ex__qimou"] = "奇谋：失去任意点体力，摸等量张牌，本回合与其他角色距离减等量，可多出等量张杀",

  ["$ol_ex__qimou1"] = "为了胜利，可以出其不意！",
  ["$ol_ex__qimou2"] = "勇战不如奇谋。",
}

qimou:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#ol_ex__qimou",
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    return UI.Spin {
      from = 1,
      to = player.hp,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(qimou.name, Player.HistoryGame) == 0 and player.hp > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local tolose = self.interaction.data
    room:loseHp(player, tolose, qimou.name)
    if player.dead then return end
    room:addPlayerMark(player, "@qimou-turn", tolose)
    player:drawCards(tolose, qimou.name)
  end,
})

qimou:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@qimou-turn")
    end
  end,
})

qimou:addEffect("distance", {
  correct_func = function(self, from, to)
    return -from:getMark("@qimou-turn")
  end,
})

return qimou