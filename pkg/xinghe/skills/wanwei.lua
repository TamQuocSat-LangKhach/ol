local wanwei = fk.CreateSkill{
  name = "ol__wanwei",
}

Fk:loadTranslationTable{
  ["ol__wanwei"] = "挽危",
  [":ol__wanwei"] = "每回合限一次，当你的牌被其他角色弃置或获得后，你可以从牌堆获得一张同名牌（无同名牌则改为摸一张牌）。",

  ["#ol__wanwei1-invoke"] = "挽危：你可以从牌堆获得一张【%arg】（若没有则摸一张牌）",
  ["#ol__wanwei2-invoke"] = "挽危：你可以从牌堆获得其中一张牌（若没有则摸一张牌）",

  ["$ol__wanwei1"] = "梁、沛之间，非子廉无有今日。",
  ["$ol__wanwei2"] = "正使祸至，共死何苦！",
}

wanwei:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(wanwei.name) and player:usedSkillTimes(wanwei.name, Player.HistoryTurn) == 0 then
      local names = {}
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if (move.moveReason == fk.ReasonPrey or move.moveReason == fk.ReasonDiscard) and move.proposer ~= player then
              table.insertIfNeed(names, Fk:getCardById(info.cardId).trueName)
            end
          end
        end
      end
      if #names > 0 then
        event:setCostData(self, {choice = names})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = event:getCostData(self).choice
    if #choices == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = wanwei.name,
        prompt = "#ol__wanwei1-invoke:::"..choices[1],
      }) then
        event:setCostData(self, {choice = choices[1]})
        return true
      end
    else
      table.insert(choices, "Cancel")
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = wanwei.name,
        prompt = "#ol__wanwei2-invoke",
      })
      if choice ~= "Cancel" then
        event:setCostData(self, {choice = choice})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(event:getCostData(self).choice)
    if #cards == 0 then
      player:drawCards(1, wanwei.name)
    else
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, wanwei.name, nil, false, player)
    end
  end,
})

return wanwei
