local ruoyu = fk.CreateSkill {
  name = "ol_ex__ruoyu",
  tags = { Skill.Lord, Skill.Wake },
}

Fk:loadTranslationTable {
  ["ol_ex__ruoyu"] = "若愚",
  [":ol_ex__ruoyu"] = "主公技，觉醒技，准备阶段，若你是体力值最小的角色，你加1点体力上限，回复体力至3点，获得〖激将〗和〖思蜀〗。",

  ["$ol_ex__ruoyu1"] = "若愚故泰，巧骗众人。",
  ["$ol_ex__ruoyu2"] = "愚昧者，非真傻也。",
}

ruoyu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ruoyu.name) and
      player:usedSkillTimes(ruoyu.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return table.every(player.room:getOtherPlayers(player, false), function(p)
      return p.hp >= player.hp
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    if player:isWounded() and player.hp < 3 then
      room:recover{
        who = player,
        num = math.min(3, player.maxHp) - player.hp,
        recoverBy = player,
        skillName = ruoyu.name,
      }
    end
    room:handleAddLoseSkills(player, "ol_ex__jijiang|ol_ex__sishu")
  end,
})

return ruoyu