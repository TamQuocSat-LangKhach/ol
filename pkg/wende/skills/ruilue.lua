local ruilue = fk.CreateSkill {
  name = "ruilue",
  tags = { Skill.Lord },
  attached_skill_name = "ruilue&",
}

Fk:loadTranslationTable {
  ["ruilue"] = "睿略",
  [":ruilue"] = "主公技，其他晋势力角色的出牌阶段限一次，该角色可以将一张【杀】或伤害锦囊牌交给你。",

  ["$ruilue1"] = "司马当兴，其兴在吾。",
  ["$ruilue2"] = "吾承父志，故知军事、通谋略。",
}

ruilue:addAcquireEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    if p.kingdom == "jin" then
      room:handleAddLoseSkills(p, "ruilue&", nil, false, true)
    else
      room:handleAddLoseSkills(p, "-ruilue&", nil, false, true)
    end
  end
end)

ruilue:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.kingdom == "jin" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(ruilue.name, true)
    end) then
      room:handleAddLoseSkills(player, ruilue.attached_skill_name, nil, false, true)
    else
      room:handleAddLoseSkills(player, "-"..ruilue.attached_skill_name, nil, false, true)
    end
  end,
})

return ruilue
