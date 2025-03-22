local jianzhi = fk.CreateSkill{
  name = "jianzhi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jianzhi"] = "谏直",
  [":jianzhi"] = "锁定技，结束阶段，你进行至多X次判定（X为你本回合发动〖切议〗的次数），你将判定牌中与你本回合使用花色相同的牌分配给任意角色；"..
  "若判定牌中有你本回合未使用过花色的牌，你受到1点无来源雷电伤害。",

  ["#jianzhi-choice"] = "谏直：选择要进行判定的次数",
  ["#jianzhi-give"] = "谏直：将这些牌分配给任意角色，点“取消”自己保留",
}

jianzhi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jianzhi.name) and player.phase == Player.Finish and
      player:usedSkillTimes("qieyi", Player.HistoryTurn) > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    for i = 1, player:usedSkillTimes("qieyi", Player.HistoryTurn), 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = jianzhi.name,
      prompt = "#jianzhi-choice",
    })
    local suits = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        table.insertIfNeed(suits, use.card:getSuitString())
      end
    end, Player.HistoryTurn)
    table.removeOne(suits, "nosuit")

    local cards = {}
    for _ = 1, tonumber(choice) do
      local judge = {
        who = player,
        reason = jianzhi.name,
        pattern = ".|.|"..table.concat(suits, ","),
      }
      room:judge(judge)
      if judge.card then
        table.insert(cards, judge.card.id)
      end
    end
    if player.dead then return end
    local ids = table.filter(cards, function (id)
      return table.contains(suits, Fk:getCardById(id):getSuitString()) and table.contains(room.discard_pile, id)
    end)
    if #ids > 0 then
      local result = room:askToYiji(player, {
        min_num = 0,
        max_num = #ids,
        skill_name = jianzhi.name,
        targets = room.alive_players,
        cards = ids,
        prompt = "#jianzhi-give",
        expand_pile = ids,
        skip = true,
      })
      for _, value in pairs(result) do
        for _, id in ipairs(value) do
          table.removeOne(ids, id)
        end
      end
      if #ids > 0 then
        table.insertTable(result[player.id], ids)
      end
      room:doYiji(result, player, jianzhi.name)
    end
    if player.dead then return end
    if table.find(cards, function (id)
      return not table.contains(suits, Fk:getCardById(id):getSuitString())
    end) then
      room:damage{
        to = player,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = jianzhi.name,
      }
    end
  end,
})

return jianzhi
