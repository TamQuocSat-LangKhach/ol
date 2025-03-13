local shuiyue = fk.CreateSkill{
  name = "shuiyue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shuiyue"] = "水月",
  [":shuiyue"] = "锁定技，回合结束时，你摸两张牌。每轮结束时，你将“水月”牌置于牌堆顶。",

  ["@@shuiyue-inhand"] = "水月",

  ["$shuiyue1"] = "灵犀失乌角，奔于野，触山壁。",
  ["$shuiyue2"] = "水中捧明月，月碎万点星光。",
}

shuiyue:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shuiyue.name)
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, shuiyue.name, "top", "@@shuiyue-inhand")
  end,
})
shuiyue:addEffect(fk.RoundEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@shuiyue-inhand") > 0
    end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@shuiyue-inhand") > 0
    end)
    if #cards > 1 then
      cards = room:askToArrangeCards(player, {
        skill_name = shuiyue.name,
        card_map = {cards, "Top"},
        free_arrange = true,
        max_limit = {#cards},
        min_limit = {#cards},
      })[1]
    end
    player.room:moveCards{
      ids = cards,
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = shuiyue.name,
      drawPilePosition = 1,
      moveVisible = false,
    }
  end,
})

return shuiyue
