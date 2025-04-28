local leishi = fk.CreateSkill{
  name = "leishi",
}

Fk:loadTranslationTable{
  ["leishi"] = "雷噬",
  [":leishi"] = "每阶段限X次（X为你上次发动〖狂信〗展示牌数），当你于出牌阶段使用本回合展示过的牌结算完成后，可以进行一次判定并获得判定牌，"..
  "若判定结果与使用牌的花色：相同，你对一名目标角色造成1点雷电伤害；不同，你展示一张牌，本回合下次判定时，若此牌在你的手牌中，将此牌作为判定牌。",

  ["#leishi-choose"] = "雷噬：对一名目标角色造成1点雷电伤害",
  ["#leishi-show"] = "雷噬：请展示一张手牌，本回合下次判定改为用此牌作为判定牌",

  ["$leishi1"] = "",
  ["$leishi2"] = "",
}

leishi:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  times = function(self, player)
    return player.phase == Player.Play and player:getMark("kuangxin") - player:usedSkillTimes(leishi.name, Player.HistoryPhase) or -1
  end,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(leishi.name) and player.phase == Player.Play and
      player:usedSkillTimes(leishi.name, Player.HistoryPhase) < player:getMark("kuangxin") and
      table.contains(player:getTableMark("leishi-turn"), data.card.id)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local pattern = ".|.|"..data.card:getSuitString()
    if data.card.suit == Card.NoSuit then
      pattern = "false"
    end
    local judge = {
      who = player,
      reason = leishi.name,
      pattern = pattern,
    }
    room:judge(judge)
    if player.dead then return end
    if judge:matchPattern() then
      local targets = table.filter(data.tos, function (p)
        return not p.dead
      end)
      if #targets > 0 then
        local to = targets[1]
        if #targets > 1 then
          to = room:askToChoosePlayers(player, {
            min_num = 1,
            max_num = 1,
            targets = targets,
            skill_name = leishi.name,
            prompt = "#leishi-choose",
            cancelable = false,
          })[1]
        end
        room:damage{
          from = player,
          to = to,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = leishi.name,
        }
      end
    elseif not player:isKongcheng() then
      local cards = player:getCardIds("h")
      if #cards > 1 then
        cards = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = leishi.name,
          prompt = "#leishi-show",
          cancelable = false,
        })
      end
      room:addTableMarkIfNeed(player, "leishi_judge-turn", cards[1])
      player:showCards(cards)
    end
  end,
})

leishi:addEffect(fk.FinishJudge, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.reason == leishi.name and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, nil, leishi.name)
  end,
})

leishi:addEffect(fk.CardShown, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(leishi.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("leishi-turn")
    for _, id in ipairs(data.cardIds) do
      if table.contains(player:getCardIds("he"), id) then
        table.insertIfNeed(mark, id)
      end
    end
    room:setPlayerMark(player, "leishi-turn", mark)
  end,
})

leishi:addEffect(fk.StartJudge, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if player:getMark("leishi_judge-turn") ~= 0 then
      local id = nil
      local ids = player:getTableMark("leishi_judge-turn")
      player.room:setPlayerMark(player, "leishi_judge-turn", 0)
      for i = #ids, 1, -1 do
        if table.contains(player:getCardIds("h"), ids[i]) then
          id = ids[i]
          break
        end
      end
      if id ~= nil then
        event:setCostData(self, {cards = {id}})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    data.card = Fk:getCardById(event:getCostData(self).cards[1])
  end,
})

return leishi
