local lianheng = fk.CreateSkill{
  name = "qin__lianheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__lianheng"] = "连横",
  [":qin__lianheng"] = "锁定技，游戏开始时，你令随机一名非秦势力角色获得“横”标记；"..
  "你的回合开始时，弃置场上的所有“横”标记，然后若非秦势力角色数不小于2，你令随机一名非秦势力角色获得“横”标记；"..
  "秦势力角色不能成为拥有“横”标记的角色使用牌的目标。",

  ["@@qin__lianheng"] = "横",

  ["$qin__lianheng"] = "连横之术，可破合纵之策。",
}

lianheng:addLoseEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:setPlayerMark(p, "@@qin__lianheng", 0)
  end
end)

lianheng:addEffect(fk.GameStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(lianheng.name) and
      table.find(player.room.alive_players, function (p)
        return p.kingdom ~= "qin"
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function (p)
      return p.kingdom ~= "qin"
    end)
    event:setCostData(self, {tos = table.random(targets, 1)})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:setPlayerMark(to, "@@qin__lianheng", 1)
  end,
})
lianheng:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(lianheng.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@@qin__lianheng", 0)
    end
    local tos = table.filter(room.alive_players, function (p)
      return p.kingdom ~= "qin"
    end)
    if #tos >= 2 then
      local to = table.random(tos)
      room:doIndicate(player, {to})
      room:setPlayerMark(to, "@@qin__lianheng", 1)
    end
  end,
})
lianheng:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if from:getMark("@@qin__lianheng") > 0 then
      return to.kingdom == "qin"
    end
  end,
})

return lianheng
