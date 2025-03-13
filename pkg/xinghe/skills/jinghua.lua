local jinghua = fk.CreateSkill{
  name = "jinghua",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jinghua"] = "镜花",
  [":jinghua"] = "锁定技，每轮开始时，你摸两张牌。回合开始时，你将“镜花”牌置于牌堆底。",

  ["@@jinghua-inhand"] = "镜花",

  ["$jinghua1"] = "白驹失蹄，踏断谁家黄花？",
  ["$jinghua2"] = "镜中花败，万般皆是虚影。",
}

jinghua:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jinghua.name)
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, jinghua.name, "top", "@@jinghua-inhand")
  end,
})
jinghua:addEffect(fk.TurnStart, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@jinghua-inhand") > 0
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@jinghua-inhand") > 0
    end)
    if #cards > 1 then
      cards = room:askToArrangeCards(player, {
        skill_name = jinghua.name,
        card_map = {cards, "Bottom"},
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
      skillName = jinghua.name,
      drawPilePosition = -1,
      moveVisible = false,
    }
  end,
})

return jinghua
