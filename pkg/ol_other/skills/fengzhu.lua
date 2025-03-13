local fengzhu = fk.CreateSkill{
  name = "fengzhu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fengzhu"] = "逢主",
  [":fengzhu"] = "锁定技，准备阶段，你拜一名其他男性角色为“义父”，摸三张牌。",

  ["#fengzhu-father"] = "逢主：拜一名男性角色为“义父”，摸三张牌",
  ["@@fengzhu_father"] = "义父",

  ["$fengzhu"] = "吕布飘零半生，只恨未逢明主，公若不弃，布愿拜为义父！",
}

fengzhu:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getTableMark(fengzhu.name)) do
    local father = room:getPlayerById(id)
    if not table.find(room.alive_players, function (p)
      return p:hasSkill(fengzhu.name, true) and not table.contains(p:getTableMark(fengzhu.name), father.id)
    end) then
      room:setPlayerMark(father, "@@fengzhu_father", 0)
    end
    room:setPlayerMark(player, fengzhu.name, 0)
  end
end)

fengzhu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengzhu.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:isMale() and not table.contains(player:getTableMark(fengzhu.name), p.id)
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local fathers = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:isMale() and not table.contains(player:getTableMark(fengzhu.name), p.id)
    end)
    local father = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = fathers,
      skill_name = fengzhu.name,
      prompt = "#fengzhu-father",
      cancelable = false,
    })[1]
    room:setPlayerMark(father, "@@fengzhu_father", 1)
    room:addTableMark(player, fengzhu.name, father.id)
    player:drawCards(3, fengzhu.name)
  end,
})

return fengzhu
