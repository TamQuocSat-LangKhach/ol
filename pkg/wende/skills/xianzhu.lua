local xianzhu = fk.CreateSkill{
  name = "ol__xianzhu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__xianzhu"] = "献珠",
  [":ol__xianzhu"] = "锁定技，出牌阶段开始时，你令一名角色获得“珠”；若不为你，其视为对你攻击范围内你指定的一名角色使用一张【杀】。",

  ["#ol__xianzhu-choose"] = "献珠：令一名角色获得“珠”（%arg），若不为你，你指定一名角色视为对其使用【杀】",
  ["#ol__xianzhu-slash"] = "献珠：选择一名角色，视为 %dest 对其使用【杀】",

  ["$ol__xianzhu1"] = "馈珠之恩，望将军莫忘。",
  ["$ol__xianzhu2"] = "愿以珠为礼，与卿交好，而休刀兵。",
}

xianzhu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xianzhu.name) and player.phase == Player.Play and
      #player:getPile("ol__lisu_zhu") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = xianzhu.name,
      prompt = "#ol__xianzhu-choose:::"..Fk:getCardById(player:getPile("ol__lisu_zhu")[1]):toLogString(),
      cancelable = false,
    })[1]
    room:obtainCard(to, player:getPile("ol__lisu_zhu"), false, fk.ReasonJustMove, to, xianzhu.name)
    if to == player or player.dead or #room.alive_players < 3 then return end
    local targets = table.filter(room:getOtherPlayers(to, false), function(p)
      return player:inMyAttackRange(p) and not to:isProhibited(p, Fk:cloneCard("slash"))
    end)
    if #targets == 0 then return end
    local p = targets[1]
    if #targets > 1 then
      p = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = xianzhu.name,
        prompt = "#ol__xianzhu-slash::"..to.id,
        cancelable = false,
      })[1]
    end
    room:useVirtualCard("slash", nil, to, p, xianzhu.name, true)
  end,
})

return xianzhu
