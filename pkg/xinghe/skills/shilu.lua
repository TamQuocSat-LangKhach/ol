local shilu = fk.CreateSkill{
  name = "shilu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shilu"] = "失路",
  [":shilu"] = "锁定技，当你受到伤害后，你摸等同体力值张牌并展示攻击范围内一名其他角色的一张手牌，令此牌视为【杀】。",

  ["#shilu-choose"] = "失路：展示一名角色的一张手牌，此牌视为【杀】",
  ["@@shilu-inhand"] = "失路",

  ["$shilu1"] = "吾计不成，吾命何归？",
  ["$shilu2"] = "烟尘四起，无处寻路。",
}

shilu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shilu.name) and
      (player.hp > 0 or table.find(player.room.alive_players, function (p)
        return player:inMyAttackRange(p) and not p:isKongcheng()
      end))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.hp > 0 then
      player:drawCards(player.hp, shilu.name)
      if player.dead then return end
    end
    local targets = table.filter(room.alive_players, function(p)
      return player:inMyAttackRange(p) and not p:isKongcheng()
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = shilu.name,
      prompt = "#shilu-choose",
      cancelable = false,
    })[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "h",
      skill_name = shilu.name,
    })
    to:showCards(id)
    if table.contains(to:getCardIds("h"), id) then
      room:setCardMark(Fk:getCardById(id), "@@shilu-inhand", 1)
      to:filterHandcards()
    end
  end,
})
shilu:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("@@shilu-inhand") > 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

return shilu
