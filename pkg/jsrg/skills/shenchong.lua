local shenchong = fk.CreateSkill {
  name = "ol__shenchong",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ol__shenchong"] = "甚宠",
  [":ol__shenchong"] = "限定技，出牌阶段，你可以令一名其他角色获得〖飞扬〗和〖跋扈〗，若如此做，当你死亡时，杀死你的角色弃置所有牌，"..
  "因此获得技能的角色失去所有技能。",

  ["#ol__shenchong"] = "甚宠：令一名其他角色获得〖飞扬〗和〖跋扈〗！",

  ["$ol__shenchong1"] = "",
  ["$ol__shenchong2"] = "",
}

shenchong:addEffect("active", {
  anim_type = "support",
  prompt = "#ol__shenchong",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(shenchong.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMarkIfNeed(player, shenchong.name, target.id)
    room:handleAddLoseSkills(target, "m_feiyang|m_bahu")
  end,
})

shenchong:addEffect(fk.Death, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark(shenchong.name) ~= 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = table.map(player:getTableMark(shenchong.name), Util.Id2PlayerMapper)
    tos = table.filter(tos, function(p)
      return not p.dead
    end)
    if data.killer and not data.killer.dead then
      table.insertIfNeed(tos, data.killer)
    end
    room:sortByAction(tos)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.killer and not data.killer.dead then
      data.killer:throwAllCards("he", shenchong.name)
    end
    local tos = table.map(player:getTableMark(shenchong.name), Util.Id2PlayerMapper)
    tos = table.filter(tos, function(p)
      return not p.dead
    end)
    for _, p in ipairs(tos) do
      if not p.dead then
        local skills = p:getSkillNameList()
        table.insert(skills, "m_feiyang")
        table.insert(skills, "m_bahu")
        room:handleAddLoseSkills(p, "-"..table.concat(skills, "|-"))
      end
    end
  end,
})

return shenchong
