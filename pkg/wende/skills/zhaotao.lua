local zhaotao = fk.CreateSkill{
  name = "zhaotao",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["zhaotao"] = "昭讨",
  [":zhaotao"] = "觉醒技，准备阶段开始时，若你本局游戏发动过至少3次〖三陈〗，你减1点体力上限，获得〖破竹〗。",

  ["$zhaotao1"] = "奉诏伐吴，定鼎东南！",
  ["$zhaotao2"] = "三陈方得诏，一股下孙吴！",
}

zhaotao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhaotao.name) and player.phase == Player.Start and
      player:usedSkillTimes(zhaotao.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes("sanchen", Player.HistoryGame) > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@sanchen", 0)
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "pozhu")
  end,
})

return zhaotao
