local juyi = fk.CreateSkill{
  name = "ol__juyi",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ol__juyi"] = "举义",
  [":ol__juyi"] = "觉醒技，准备阶段，若你体力上限大于存活角色数，你摸X张牌（X为你的体力上限），然后获得技能〖崩坏〗和〖威重〗。",

  ["$ol__juyi1"] = "司马氏，定不攻自败也。",
  ["$ol__juyi2"] = "义照淮流，身报国恩！",
}

juyi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juyi.name) and player.phase == Player.Start and
      player:usedSkillTimes(juyi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.maxHp > #player.room.alive_players
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp, juyi.name)
    if player.dead then return end
    player.room:handleAddLoseSkills(player, "benghuai|ol__weizhong")
  end,
})

return juyi
