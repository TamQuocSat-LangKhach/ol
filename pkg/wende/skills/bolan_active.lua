local bolan_active = fk.CreateSkill{
  name = "bolan&",
}

Fk:loadTranslationTable{
  ["bolan&"] = "博览",
  [":bolan&"] = "出牌阶段限一次，你可以失去1点体力，令钟琰从随机三个“出牌阶段限一次”的技能中选择一个，你获得之直到此阶段结束。",

  ["#bolan"] = "博览：你可以失去1点体力，令钟琰从三个“出牌阶段限一次”的技能中选择一个令你获得",
}

---@param room Room
local getBolanSkills = function(room)
  local mark = room:getBanner("BolanSkills")
  if mark then
    return mark
  else
    local all_skills = {}
    for _, g in ipairs(room.general_pile) do
      for _, s in ipairs(Fk.generals[g]:getSkillNameList()) do
        table.insert(all_skills, s)
      end
    end
    local skills = table.filter(BolanSkills, function(s) return table.contains(all_skills, s) end)
    room:setBanner("BolanSkills", skills)
    return skills
  end
end

bolan_active:addEffect("active", {
  prompt = "#bolan",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(bolan_active.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function (p)
        return p:hasSkill("bolan")
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = table.find(room:getOtherPlayers(player, false), function(p)
      return p:hasSkill("bolan")
    end)
    if not target then return end
    target:broadcastSkillInvoke("bolan")
    room:doIndicate(player, {target})
    room:loseHp(player, 1, "bolan")
    if player.dead or target.dead then return end
    local skills = table.filter(getBolanSkills(room), function (skill_name)
      return not player:hasSkill(skill_name, true)
    end)
    if #skills > 0 then
      local choice = room:askToChoice(target, {
        choices = table.random(skills, 3),
        skill_name = "bolan",
        prompt = "#bolan-choice::"..player.id,
        detailed = true,
      })
      room:handleAddLoseSkills(player, choice)
      room.logic:getCurrentEvent():findParent(GameEvent.Phase):addCleaner(function()
        room:handleAddLoseSkills(player, "-"..choice)
      end)
    end
  end,
})

return bolan_active
