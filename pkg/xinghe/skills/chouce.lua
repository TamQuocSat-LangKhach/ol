local chouce = fk.CreateSkill{
  name = "chouce",
}

Fk:loadTranslationTable{
  ["chouce"] = "筹策",
  [":chouce"] = "当你受到1点伤害后，你可以进行判定，若结果为：黑色，你弃置一名角色区域里的一张牌；红色，你令一名角色摸一张牌（先辅的角色摸两张）。",

  ["#chouce-draw"] = "筹策: 令一名角色摸一张牌（若为先辅角色则摸两张）",
  ["#chouce-discard"] = "筹策: 弃置一名角色区域里的一张牌",

  ["$chouce1"] = "一筹一划，一策一略。",
  ["$chouce2"] = "主公之忧，吾之所思也。",
}

local updataXianfu = function (room, player, target)
  local mark = player:getTableMark("xianfu")
  table.insertIfNeed(mark[2], target.id)
  room:setPlayerMark(player, "xianfu", mark)
  local names = table.map(mark[2], function(pid) return Fk:translate(room:getPlayerById(pid).general) end)
  room:setPlayerMark(player, "@xianfu", table.concat(names, ","))
end

chouce:addEffect(fk.Damaged, {
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chouce.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if player.dead then return false end
    if judge.card.color == Card.Red then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = chouce.name,
        prompt = "#chouce-draw",
        cancelable = false,
      })[1]
      local num = 1
      local mark = player:getTableMark("xianfu")
      if #mark > 0 and table.contains(mark[1], to.id) then
        num = 2
        updataXianfu (room, player, to)
      end
      to:drawCards(num, chouce.name)
    elseif judge.card.color == Card.Black then
      local targets = table.filter(room.alive_players, function(p)
        return not p:isAllNude()
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = chouce.name,
        prompt = "#chouce-discard",
        cancelable = false,
      })[1]
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "hej",
        skill_name = chouce.name,
      })
      room:throwCard(card, chouce.name, to, player)
    end
  end,
})

return chouce
