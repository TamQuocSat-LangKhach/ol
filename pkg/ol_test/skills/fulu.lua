local fulu = fk.CreateSkill{
  name = "fulux",
}

Fk:loadTranslationTable{
  ["fulux"] = "负掳",
  [":fulux"] = "当你使用【杀】结算后，你可以交给一名目标角色一张手牌，然后获得其至多两张手牌。体力值小于你的角色使用【杀】结算后，"..
  "若你为此【杀】目标，其可以交给你一张手牌，然后获得你至多两张手牌。",

  ["#fulux-choose"] = "负掳：你可以交给一名目标角色一张手牌，获得其至多两张手牌",
  ["#fulux-invoke"] = "负掳：你可以交给 %src 一张手牌，获得其至多两张手牌",

  ["$fulux1"] = "藏什么呢？快拿出来孝敬本将军！",
  ["$fulux2"] = "好个无礼的家伙，上来就抢人家宝剑！",
}

fulu:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(fulu.name) and data.card.trueName == "slash" then
      if target == player then
        return not player:isKongcheng() and
          table.find(data.tos, function (p)
            return not p.dead
          end)
      else
        return not target:isKongcheng() and table.contains(data.tos, player) and not target.dead and
          target.hp < player.hp
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if target == player then
      local targets = table.filter(data.tos, function (p)
        return not p.dead
      end)
      local to, card = targets, {}
      if #targets > 1 then
        to, card = room:askToChooseCardsAndPlayers(player, {
          min_card_num = 1,
          max_card_num = 1,
          min_num = 1,
          max_num = 1,
          targets = data.tos,
          pattern = ".|.|.|hand",
          skill_name = fulu.name,
          prompt = "#fulux-choose",
          cancelable = true,
        })
      else
        card = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = fulu.name,
          prompt = "#fulux-invoke:"..to[1].id,
          cancelable = true,
        })
      end
      if #to > 0 and #card == 1 then
        event:setCostData(self, {tos = to, cards = card})
        return true
      end
    else
      local cards = room:askToCards(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = fulu.name,
        prompt = "#fulux-invoke:"..player.id,
        cancelable = true,
      })
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = target == player and event:getCostData(self).tos[1] or player
    if to == player then
      player:broadcastSkillInvoke(fulu.name, 2)
      room:notifySkillInvoked(player, fulu.name, "negative")
    else
      player:broadcastSkillInvoke(fulu.name, 1)
      room:notifySkillInvoked(player, fulu.name, "offensive")
    end
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, fulu.name, nil, false, target)
    if target.dead or to.dead or to:isKongcheng() then return end
    local cards = room:askToChooseCards(target, {
      target = to,
      min = 1,
      max = 2,
      flag = "h",
      skill_name = fulu.name,
    })
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonPrey, fulu.name, nil, false, target)
  end,
})

return fulu
