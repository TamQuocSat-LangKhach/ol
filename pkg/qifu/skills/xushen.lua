local xushen = fk.CreateSkill{
  name = "ol__xushen",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ol__xushen"] = "许身",
  [":ol__xushen"] = "限定技，当你进入濒死状态时，你可以回复体力至1并获得〖镇南〗，然后若关索不在场，你可以令一名男性角色选择是否用关索代替其武将牌。",

  ["#ol__xushen-choose"] = "许身：你可以令一名男性角色选择是否变身为关索！",
  ["#ol__xushen-invoke"]= "许身：你可以变身为关索！",

  ["$ol__xushen1"] = "救命之恩，涌泉相报。",
  ["$ol__xushen2"] = "解我危难，报君华彩。",
}

xushen:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xushen.name) and
      player.dying and player:usedSkillTimes(xushen.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover{
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = xushen.name,
    }
    if player.dead then return end
    room:handleAddLoseSkills(player, "ol__zhennan")
    if table.find(room.alive_players, function (p)
      return string.find(p.general, "guansuo") or string.find(p.deputyGeneral, "guansuo")
    end) then
      return
    end
    local targets = table.filter(room.alive_players, function(p)
      return p:isMale()
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = xushen.name,
      prompt = "#ol__xushen-choose",
      cancelable = true,
    })
    if #to > 0 and room:askToSkillInvoke(to[1], {
      skill_name = xushen.name,
      prompt = "#ol__xushen-invoke",
    }) then
      room:changeHero(to, "ol__guansuo", false, false, true)
    end
  end,
})

return xushen
