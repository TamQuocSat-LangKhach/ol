local naxiang = fk.CreateSkill{
  name = "naxiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["naxiang"] = "纳降",
  [":naxiang"] = "锁定技，当其他角色对你造成伤害或受到你的伤害后，你对其发动〖才望〗的“弃置”修改为“获得”直到你的回合开始。",

  ["@@naxiang"] = "纳降",

  ["$naxiang1"] = "奉命伐吴，得胜纳降。",
  ["$naxiang2"] = "进军逼江，震慑吴贼。",
}

naxiang:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getTableMark(naxiang.name)) do
    local p = room:getPlayerById(id)
    if not p.dead and not table.find(room:getOtherPlayers(player, false), function(p2)
      return table.contains(p:getTableMark(naxiang.name), p2)
    end) then
      room:setPlayerMark(p, "@@naxiang", 0)
    end
  end
  room:setPlayerMark(player, naxiang.name, 0)
end)

naxiang:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(naxiang.name) and not data.to.dead and
      not table.contains(player:getTableMark(naxiang.name), data.to.id)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(data.to, "@@naxiang", 1)
    room:addTableMark(player, naxiang.name, data.to.id)
  end,
})
naxiang:addEffect(fk.Damaged, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(naxiang.name) and data.from and not data.from.dead and
      not table.contains(player:getTableMark(naxiang.name), data.from.id)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(data.from, "@@naxiang", 1)
    room:addTableMark(player, naxiang.name, data.from.id)
  end,
})
naxiang:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(naxiang.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getMark(naxiang.name)) do
      local p = room:getPlayerById(id)
      if not p.dead and not table.find(room:getOtherPlayers(player, false), function(p2)
        return table.contains(p:getTableMark(naxiang.name), p2)
      end) then
        room:setPlayerMark(p, "@@naxiang", 0)
      end
    end
    room:setPlayerMark(player, naxiang.name, 0)
  end,
})

return naxiang
