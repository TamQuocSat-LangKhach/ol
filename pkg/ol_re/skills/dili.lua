local dili = fk.CreateSkill{
  name = "dili",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["dili"] = "帝力",
  [":dili"] = "觉醒技，当你的技能数超过体力上限后，你减少1点体力上限，失去任意个其他技能并获得〖圣质〗〖权道〗〖持纲〗中的前等量个。",

  ["#dili-invoke"] = "帝力：选择失去至多三个技能",
  [":Cancel"] = "取消",

  ["$dili1"] = "身处巅峰，览天下大事。",
  ["$dili2"] = "位居至尊，掌至高之权。",
}

local spec = {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dili.name) and
      player:usedSkillTimes(dili.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getSkillNameList() > player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    local skills = player:getSkillNameList()
    local result = room:askToCustomDialog(player, {
      skill_name = dili.name,
      qml_path = "packages/utility/qml/ChooseSkillBox.qml",
      extra_data = {
        skills, 0, 3, "#dili-invoke",
      },
    })
    if result == "" then return end
    local choice = json.decode(result)
    if #choice > 0 then
      room:handleAddLoseSkills(player, "-"..table.concat(choice, "|-"))
      skills = {"shengzhi", "quandao", "chigang"}
      local skill = {}
      for i = 1, #choice, 1 do
        if i > 3 then break end
        table.insert(skill, skills[i])
      end
      room:handleAddLoseSkills(player, table.concat(skill, "|"))
    end
  end,
}

dili:addEffect(fk.EventAcquireSkill, spec)
dili:addEffect(fk.MaxHpChanged, spec)

return dili
