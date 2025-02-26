local huangtian = fk.CreateSkill {
  name = "ol_ex__huangtian",
  attached_skill_name = "ol_ex__huangtian_active&",
}

Fk:loadTranslationTable {
  ["ol_ex__huangtian"] = "黄天",
  [":ol_ex__huangtian"] = "主公技，其他群势力角色的出牌阶段限一次，该角色可以将一张【闪】或♠手牌（正面朝上移动）交给你。",

  ["$ol_ex__huangtian1"] = "黄天法力，万军可灭！",
  ["$ol_ex__huangtian2"] = "天书庇佑，黄巾可兴！",
}

huangtian:addAcquireEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    if p.kingdom == "qun" then
      room:handleAddLoseSkills(p, "ol_ex__huangtian_active&", nil, false, true)
    else
      room:handleAddLoseSkills(p, "-ol_ex__huangtian_active&", nil, false, true)
    end
  end
end)

huangtian:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.kingdom == "qun" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(huangtian.name, true)
    end) then
      room:handleAddLoseSkills(player, huangtian.attached_skill_name, nil, false, true)
    else
      room:handleAddLoseSkills(player, "-" .. huangtian.attached_skill_name, nil, false, true)
    end
  end,
})

return huangtian
