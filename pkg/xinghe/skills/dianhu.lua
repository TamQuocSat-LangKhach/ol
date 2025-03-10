local dianhu = fk.CreateSkill{
  name = "dianhu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dianhu"] = "点虎",
  [":dianhu"] = "锁定技，游戏开始时，你指定一名其他角色；当你对该角色造成伤害后或该角色回复体力后，你摸一张牌。",

  ["@@dianhu"] = "点虎",
  ["#dianhu-choose"] = "点虎：指定一名角色，本局当你对其造成伤害或其回复体力后，你摸一张牌",

  ["$dianhu1"] = "预则立，不预则废！",
  ["$dianhu2"] = "就用你，给我军祭旗！",
}

dianhu:addLoseEffect(function (self, player, is_death)
  if is_death and player:getMark(dianhu.name) ~= 0 then
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if table.contains(player:getTableMark(dianhu.name), p.id) and
        not table.find(room:getOtherPlayers(player, false), function (q)
          return table.contains(q:getTableMark(dianhu.name), p.id)
        end) then
        room:setPlayerMark(p, "@@dianhu", 0)
      end
    end
  end
end)

dianhu:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dianhu.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = dianhu.name,
      prompt = "#dianhu-choose",
      cancelable = false,
    })[1]
    room:setPlayerMark(to, "@@dianhu", 1)
    room:addTableMark(player, dianhu.name, to.id)
  end,
})
dianhu:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and table.contains(player:getTableMark(dianhu.name), data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, dianhu.name)
  end,
})
dianhu:addEffect(fk.HpRecover, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return table.contains(player:getTableMark(dianhu.name), target.id)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, dianhu.name)
  end,
})

return dianhu
