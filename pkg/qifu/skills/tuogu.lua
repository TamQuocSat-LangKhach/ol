local tuogu = fk.CreateSkill{
  name = "tuogu",
}

Fk:loadTranslationTable{
  ["tuogu"] = "托孤",
  [":tuogu"] = "当一名角色死亡时，你可以令其选择其武将牌上的一个技能（限定技、觉醒技、主公技、隐匿技、使命技除外），你失去上次以此法获得的技能，"..
  "然后获得此技能。",

  ["#tuogu-invoke"] = "托孤：你可以令 %dest 选择其一个技能令你获得",
  ["#tuogu-choice"] = "托孤：选择令 %src 获得的一个技能",

  ["$tuogu1"] = "君托以六尺之孤，爽，当寄百里之命。",
  ["$tuogu2"] = "先帝以大事托我，任重而道远。",
}

tuogu:addEffect(fk.Deathed, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tuogu.name) then
      local all_skills = Fk.generals[target.general]:getSkillNameList()
      if target.deputyGeneral ~= "" then
        table.insertTableIfNeed(all_skills, Fk.generals[target.deputyGeneral]:getSkillNameList())
      end
      local skills = {}
      for _, s in ipairs(all_skills) do
        if not player:hasSkill(s, true) then
          local skill = Fk.skills[s]
          if not table.find({Skill.Limited, Skill.Wake, Skill.Lord, Skill.Hidden, Skill.Quest}, function (tag)
            return skill:hasTag(tag)
          end) then
            if skill:hasTag(Skill.AttachedKingdom) then
              if table.contains(skill:getSkeleton().attached_kingdom, player.kingdom) then
                table.insert(skills, s)
              end
            else
              table.insert(skills, s)
            end
          end
        end
      end
      if #skills > 0 then
        event:setCostData(self, {extra_data = skills})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = tuogu.name,
      prompt = "#tuogu-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}, extra_data = event:getCostData(self).extra_data})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(target, {
      choices = event:getCostData(self).extra_data,
      skill_name = tuogu.name,
      prompt = "#tuogu-choice:"..player.id,
    })
    local mark = player:getMark(tuogu.name)
    room:setPlayerMark(player, tuogu.name, choice)
    if mark ~= 0 then
      choice = "-"..mark.."|"..choice
    end
    room:handleAddLoseSkills(player, choice)
  end,
})
tuogu:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(tuogu.name) == data.skill.name
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, tuogu.name, 0)
  end,
})

return tuogu
