local aige = fk.CreateSkill{
  name = "aige",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["aige"] = "哀歌",
  [":aige"] = "觉醒技，一回合内第二次有角色进入濒死状态后，你失去〖西向〗，获得〖逐北〗，然后将手牌摸至X张，体力值回复至X点。（X为该角色体力上限）",

  ["$aige1"] = "奈何力不齐，踌躇而雁行。",
  ["$aige2"] = "生民百遗一，念之断人肠。",
}

aige:addEffect(fk.AfterDying, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(aige.name) and player:usedSkillTimes(aige.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    --FIXME: AfterDying时机在exit中，取不到当前事件……
    return #player.room.logic:getEventsOfScope(GameEvent.Dying, 3, Util.TrueFunc, Player.HistoryTurn) == 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-xixiang|zhubei")
    local n = target.maxHp
    if player:getHandcardNum() < n then
      player:drawCards(n - player:getHandcardNum(), aige.name)
    end
    if not player.dead and player.hp < n and player:isWounded() then
      room:recover{
        who = player,
        num = n - player.hp,
        recoverBy = player,
        skillName = aige.name,
      }
    end
  end,
})

return aige
