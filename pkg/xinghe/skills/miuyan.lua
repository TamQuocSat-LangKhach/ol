local miuyan = fk.CreateSkill{
  name = "miuyan",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["miuyan"] = "谬焰",
  [":miuyan"] = "转换技，阳：你可以将一张黑色牌当【火攻】使用，若此牌造成伤害，你获得本阶段展示过的所有手牌；"..
  "阴：你可以将一张黑色牌当【火攻】使用，若此牌未造成伤害，本轮本技能失效。",

  ["#miuyan-yang"] = "谬焰：将一张黑色牌当【火攻】使用，若造成伤害，获得本阶段展示过的所有手牌",
  ["#miuyan-yin"] = "谬焰：将一张黑色牌当【火攻】使用，若未造成伤害，本轮“谬焰”失效",

  ["$miuyan1"] = "未时引火，必大败蜀军。",
  ["$miuyan2"] = "我等诈降，必欺姜维于不意。",
}

miuyan:addEffect("viewas", {
  anim_type = "switch",
  pattern = "fire_attack",
  prompt = function (self, player)
    return "#miuyan-".. player:getSwitchSkillState(miuyan.name, false, true)
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = miuyan.name
    card:addSubcard(cards[1])
    return card
  end,
  after_use = function (self, player, use)
    if player.dead then return end
    local room = player.room
    if player:getSwitchSkillState(miuyan.name, true) == fk.SwitchYang then
      if use.damageDealt then
        local moves = {}
        for _, p in ipairs(room:getOtherPlayers(player, false)) do
          if not p:isKongcheng() then
            local cards = {}
            for _, id in ipairs(p:getCardIds("h")) do
              if Fk:getCardById(id):getMark("miuyan-phase") > 0 then
                table.insertIfNeed(cards, id)
              end
            end
            if #cards > 0 then
              table.insert(moves, {
                from = p,
                ids = cards,
                to = player,
                toArea = Card.PlayerHand,
                moveReason = fk.ReasonPrey,
                proposer = player,
                skillName = miuyan.name,
              })
            end
          end
        end
        if #moves > 0 then
          room:moveCards(table.unpack(moves))
        end
      end
    else
      if not use.damageDealt then
        room:invalidateSkill(player, miuyan.name, "-round")
      end
    end
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})
miuyan:addEffect(fk.CardShown, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(data.cardIds) do
      if table.contains(player:getCardIds("h"), id) then
        room:setCardMark(Fk:getCardById(id), "miuyan-phase", 1)
      end
    end
  end,
})

return miuyan
