local pengbi = fk.CreateSkill{
  name = "pengbi",
}

Fk:loadTranslationTable{
  ["pengbi"] = "朋比",
  [":pengbi"] = "你的第一个回合开始时，你选择获得〖隐天〗〖蔽日〗中的一个技能，然后可以令一名其他角色获得另一个技能。",

  ["#pengbi-choice"] = "朋比：获得一个技能，然后可以令一名其他角色获得另一个技能",
  ["#pengbi-choose"] = "朋比：你可以令一名其他角色获得“%arg”",

  ["$pengbi1"] = "",
  ["$pengbi2"] = "",
}

pengbi:addEffect(fk.TurnStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(pengbi.name) and
      player:usedSkillTimes(pengbi.name, Player.HistoryGame) == 0 and
      not (player:hasSkill("yintian", true) and player:hasSkill("biri", true)) and
      #player.room.logic:getEventsOfScope(GameEvent.Turn, 2, function (e)
        return e.data.who == player
      end, Player.HistoryGame) == 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choices = {"yintian", "biri"}
    choices = table.filter(choices, function (s)
      return not player:hasSkill(s, true)
    end)
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = pengbi.name,
      prompt = "#pengbi-choice",
      all_choices = {"yintian", "biri"},
      detailed = true,
    })
    room:handleAddLoseSkills(player, choice)
    local skill = choice == "yintian" and "biri" or "yintian"
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not player:hasSkill(skill, true)
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = pengbi.name,
      prompt = "#pengbi-choose:::"..skill,
      cancelable = true,
    })
    if #to > 0 then
      room:handleAddLoseSkills(to[1], skill)
    end
  end,
})

return pengbi
