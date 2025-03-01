local jisi = fk.CreateSkill{
  name = "jisi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["jisi"] = "羁肆",
  [":jisi"] = "限定技，准备阶段，你可以令一名角色获得此武将牌上发动过的一个技能，然后你弃置所有手牌并视为对其使用一张【杀】。",

  ["#jisi-choose"] = "羁肆：你可以令一名角色获得一个你发动过的技能，然后你弃置所有手牌并视为对其使用【杀】",

  ["$jisi1"] = "被褐怀玉，天放不羁。",
  ["$jisi2"] = "心若野马，不系璇台。",
}

jisi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jisi.name) and player.phase == Player.Start and
      player:usedSkillTimes(jisi.name, Player.HistoryGame) == 0 then
      local all_skills = Fk.generals[player.general]:getSkillNameList()
      if table.contains(all_skills, jisi.name) then
        for _, skill_name in ipairs(all_skills) do
          if player:usedSkillTimes(skill_name, Player.HistoryGame) > 0 then
            return true
          end
        end
      end
      if player.deputyGeneral and player.deputyGeneral ~= "" then
        local all_deputy_skills = Fk.generals[player.deputyGeneral]:getSkillNameList()
        if table.contains(all_deputy_skills, jisi.name) then
          for _, skill_name in ipairs(all_deputy_skills) do
            if player:usedSkillTimes(skill_name, Player.HistoryGame) > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "jisi_active",
      prompt = "#jisi-choose",
      no_indicate = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:handleAddLoseSkills(to, event:getCostData(self).choice)
    player:throwAllCards("h", jisi.name)
    if not player.dead and not to.dead then
      room:useVirtualCard("slash", nil, player, to, jisi.name, true)
    end
  end,
})

return jisi
