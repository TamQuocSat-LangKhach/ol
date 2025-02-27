local niepan = fk.CreateSkill{
  name = "ol_ex__niepan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["ol_ex__niepan"] = "涅槃",
  [":ol_ex__niepan"] = "限定技，当你处于濒死状态时，你可以：弃置区域里的所有牌，复原武将牌，"..
  "摸三张牌，将体力回复至3点，选择下列一个技能并获得之：〖八阵〗、〖火计〗、〖看破〗。",

  ["#ol_ex__niepan-choice"] = "涅槃：选择获得一项技能",

  ["$ol_ex__niepan1"] = "烈火脱胎，涅槃重生。",
  ["$ol_ex__niepan2"] = "破而后立，方有大成。",
}

niepan:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(niepan.name) and player.dying and
      player:usedSkillTimes(niepan.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("hej", niepan.name)
    if player.dead then return false end
    player:reset()
    if player.dead then return false end
    player:drawCards(3, niepan.name)
    if player.dead then return false end
    if player:isWounded() then
      room:recover{
        who = player,
        num = math.min(3, player.maxHp) - player.hp,
        recoverBy = player,
        skillName = niepan.name,
      }
      if player.dead then return false end
    end
    local wolong_skills = {"bazhen", "ol_ex__huoji", "ol_ex__kanpo"}
    local choices = table.filter(wolong_skills, function (skill_name)
      return not player:hasSkill(skill_name, true)
    end)
    if #choices == 0 then return false end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = niepan.name,
      prompt = "#ol_ex__niepan-choice",
      detailed = true,
      all_choices = wolong_skills,
    })
    room:handleAddLoseSkills(player, choice)
  end,
})

return niepan