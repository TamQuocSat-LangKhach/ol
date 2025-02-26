local jiewei = fk.CreateSkill{
  name = "ol_ex__jiewei",
}

Fk:loadTranslationTable{
  ["ol_ex__jiewei"] = "解围",
  [":ol_ex__jiewei"] = "你可将一张装备区里的牌当【无懈可击】使用。当你翻面后，若你的武将牌正面朝上，你可以弃置一张牌，然后移动场上一张牌。",

  ["#ol_ex__jiewei-discard"] = "解围：你可以弃置一张牌，然后移动场上一张牌",
  ["#ol_ex__jiewei-choose"] = "解围：你可以移动场上的一张牌",

  ["$ol_ex__jiewei1"] = "化守为攻，出奇制胜！",
  ["$ol_ex__jiewei2"] = "坚壁清野，以挫敌锐！",
}

jiewei:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "nullification",
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Equip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("nullification")
    c.skillName = jiewei.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function (self, player, response)
    return not response and #player:getCardIds("e") > 0
  end,
})

jiewei:addEffect(fk.TurnedOver, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiewei.name) and not player:isNude() and player.faceup
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jiewei.name,
      cancelable = true,
      prompt = "#ol_ex__jiewei-discard",
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, jiewei.name, player, player)
    if player.dead or #room:canMoveCardInBoard() == 0 then return false end
    local to = room:askToChooseToMoveCardInBoard(player, {
      prompt = "#ol_ex__jiewei-choose",
      skill_name = jiewei.name,
      cancelable = true,
    })
    if #to == 2 then
      room:askToMoveCardInBoard(player, {
        target_one = to[1],
        target_two = to[2],
        skill_name = jiewei.name,
      })
    end
  end,
})

return jiewei