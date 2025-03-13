local yuyu = fk.CreateSkill{
  name = "yuyu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yuyu"] = "郁郁",
  [":yuyu"] = "锁定技，你的回合结束时，你令一名“义父”获得一枚“恨”标记。你于其回合每受到1点伤害或每失去一张牌后，其获得一枚“恨”标记。",

  ["@lvbu_hate"] = "恨",
  ["#yuyu-hate"] = "郁郁：令一名“义父”获得一枚“恨”标记",

  ["$yuyu"] = "大丈夫生居天地之间，岂能郁郁久居人下！",
}

yuyu:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuyu.name) and
      table.find(player:getTableMark("fengzhu"), function (id)
        return not player.room:getPlayerById(id).dead
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local father = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = table.map(player:getTableMark("fengzhu"), Util.Id2PlayerMapper),
      skill_name = yuyu.name,
      prompt = "#yuyu-hate",
      cancelable = false,
    })[1]
    room:addPlayerMark(father, "@lvbu_hate", 1)
  end,
})
yuyu:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuyu.name) and
      table.contains(player:getTableMark("fengzhu"), player.room.current.id) and
      not player.room.current.dead
  end,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player.room.current, "@lvbu_hate", data.damage)
  end,
})
yuyu:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuyu.name) and table.contains(player:getTableMark("fengzhu"), player.room.current.id) and
      not player.room.current.dead then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            n = n + 1
          end
        end
      end
    end
    room:addPlayerMark(room.current, "@lvbu_hate", n)
  end,
})

return yuyu
