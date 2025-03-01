local jisi_active = fk.CreateSkill{
  name = "jisi_active",
}

Fk:loadTranslationTable{
  ["jisi_active"] = "羁肆",
}

jisi_active:addEffect("active", {
  interaction = function(self, player)
    local skills = {}
    local all_skills = Fk.generals[player.general]:getSkillNameList()
    if table.contains(all_skills, "jisi") then
      for _, skill_name in ipairs(all_skills) do
        if player:usedSkillTimes(skill_name, Player.HistoryGame) > 0 then
          table.insertIfNeed(skills, skill_name)
        end
      end
    end
    if player.deputyGeneral and player.deputyGeneral ~= "" then
      local all_deputy_skills = Fk.generals[player.deputyGeneral]:getSkillNameList()
      if table.contains(all_deputy_skills, "jisi") then
        for _, skill_name in ipairs(all_deputy_skills) do
          if player:usedSkillTimes(skill_name, Player.HistoryGame) > 0 then
            table.insertIfNeed(skills, skill_name)
          end
        end
      end
    end
    return UI.ComboBox { choices = skills }
  end,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return self.interaction.data ~= nil and #selected == 0 and to_select ~= player
  end,
})

return jisi_active
