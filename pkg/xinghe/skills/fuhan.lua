local fuhan = fk.CreateSkill{
  name = "fuhan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["fuhan"] = "扶汉",
  [":fuhan"] = "限定技，准备阶段，你可以移去所有“梅影”标记，随机观看五名未登场的蜀势力角色，将武将牌替换为其中一名角色，"..
  "并将体力上限数调整为本局游戏中移去“梅影”标记的数量（至少2，至多8），然后若你是体力值最低的角色，你回复1点体力。",

  ["#fuhan-invoke"] = "扶汉：你可以变身为一名蜀势力武将！（体力上限为%arg）",

  ["$fuhan1"] = "承先父之志，扶汉兴刘。",
  ["$fuhan2"] = "天将降大任于我。",
}

fuhan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuhan.name) and player.phase == Player.Start and
      player:usedSkillTimes(fuhan.name, Player.HistoryGame) == 0 and player:getMark("@meiying") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local maxHp = math.max(player:usedEffectTimes("fanghun", Player.HistoryGame), 2)
    maxHp = math.min(maxHp, 8)
    return player.room:askToSkillInvoke(player, {
      skill_name = fuhan.name,
      prompt = "#fuhan-invoke:::"..maxHp,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    local generals = room:findGenerals(function(g)
      return Fk.generals[g].kingdom == "shu"
    end, 5)
    local general = room:askToChooseGeneral(player, {
      generals = generals,
      n = 1,
      no_convert = true,
    })
    room:changeHero(player, general, false, false, true)
    local maxHp = math.max(n + player:usedEffectTimes("fanghun", Player.HistoryGame), 2)
    maxHp = math.min(maxHp, 8)
    room:changeMaxHp(player, maxHp - player.maxHp)
    player.gender = Fk.generals[player.general].gender
    room:broadcastProperty(player, "gender")
    if player.hp == 0 then
      room:killPlayer({
        who = player,
      })
    end
    if table.every(room:getOtherPlayers(player, false), function(p)
      return p.hp >= player.hp
    end) and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = fuhan.name,
      }
    end
  end,
})

return fuhan
