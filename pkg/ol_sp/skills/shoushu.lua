local shoushu = fk.CreateSkill{
  name = "ol__shoushu",
}

Fk:loadTranslationTable{
  ["ol__shoushu"] = "授术",
  [":ol__shoushu"] = "出牌阶段限一次，你可以将一册未翻开的<a href='tianshu_href'>“天书”</a>交给一名其他角色。",

  ["#ol__shoushu"] = "授术：你可以将一册未翻开的“天书”交给一名其他角色",
  ["#ol__shoushu-give"] = "授术：选择交给 %dest 的“天书”",

  ["$ol__shoushu1"] = "此书载天地至理，望汝珍视如命。",
  ["$ol__shoushu2"] = "天书非凡物，字字皆玄机。",
  ["$ol__shoushu3"] = "我得道成仙，当出世化生人中。",
}

shoushu:addEffect("active", {
  anim_type = "support",
  prompt = "#ol__shoushu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(shoushu.name, Player.HistoryPhase) == 0 and
      table.find(player:getTableMark("@[tianshu]"), function (info)
        return player:usedSkillTimes(info.skillName, Player.HistoryGame) == 0
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local skills = table.filter(player:getTableMark("@[tianshu]"), function (info)
      return player:usedSkillTimes(info.skillName, Player.HistoryGame) == 0
    end)
    skills = table.map(skills, function (info)
      return info.skillName
    end)
    local args = {}
    for _, s in ipairs(skills) do
      local info = room:getBanner("tianshu_skills")[s]
      table.insert(args, Fk:translate(":tianshu_triggers"..info[1]).."，"..Fk:translate(":tianshu_effects"..info[2]).."。")
    end
    local choice = room:askToChoice(player, {
      choices = args,
      skill_name = shoushu.name,
      prompt = "#ol__shoushu-give::"..target.id,
    })
    local skill = skills[table.indexOf(args, choice)]
    if #target:getTableMark("@[tianshu]") > target:getMark("tianshu_max") then
      skills = table.map(target:getTableMark("@[tianshu]"), function (info)
        return info.skillName
      end)
      local to_throw = skills[1]
      if #skills > 1 then
        args = {}
        for _, s in ipairs(skills) do
          local info = room:getBanner("tianshu_skills")[s]
          table.insert(args, Fk:translate(":tianshu_triggers"..info[1]).."，"..Fk:translate(":tianshu_effects"..info[2]).."。")
        end
        choice = room:askToChoice(target, {
          choices = args,
          skill_name = shoushu.name,
          prompt = "#ol__shoushu-discard",
        })
        to_throw = skills[table.indexOf(args, choice)]
      end
      room:handleAddLoseSkills(target, "-"..to_throw)
      local banner = room:getBanner("tianshu_skills")
      banner[to_throw] = nil
      room:setBanner("tianshu_skills", banner)
    end
    room:handleAddLoseSkills(player, "-"..skill)
    room:handleAddLoseSkills(target, skill)
  end,
})

return shoushu
