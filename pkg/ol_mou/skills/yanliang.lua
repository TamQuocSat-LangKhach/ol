local yanliang = fk.CreateSkill{
  name = "yanliangy",
  tags = { Skill.Lord },
  attached_skill_name = "yanliangy&",
}

Fk:loadTranslationTable{
  ["yanliangy"] = "厌粱",
  [":yanliangy"] = "主公技，其他群势力角色出牌阶段限一次，其可以交给你一张装备牌，视为使用一张【酒】。",

  ["$yanliangy1"] = "此酒酸涩，快！去取我的金浆酒来！",
  ["$yanliangy2"] = "诸君且饮此杯，待明日沙场建功！",
}

yanliang:addAcquireEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    if p.kingdom == "qun" then
      room:handleAddLoseSkills(p, "yanliangy&", nil, false, true)
    else
      room:handleAddLoseSkills(p, "-yanliangy&", nil, false, true)
    end
  end
end)

yanliang:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.kingdom == "qun" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(yanliang.name, true)
    end) then
      room:handleAddLoseSkills(player, "yanliangy&", nil, false, true)
    else
      room:handleAddLoseSkills(player, "-yanliangy&", nil, false, true)
    end
  end,
})


return yanliang
