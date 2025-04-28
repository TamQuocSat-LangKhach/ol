local fengwei = fk.CreateSkill{
  name = "fengwei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fengwei"] = "丰蔚",
  [":fengwei"] = "锁定技，每轮开始时，你摸至多四张牌；当你手牌中有本轮以此法获得的牌时，你受到牌造成的伤害+1。",

  ["#fengwei-choice"] = "丰蔚：摸至多四张牌，本轮手牌中有这些牌时受到伤害+1",
  ["@@fengwei-inhand-round"] = "丰蔚",

  ["$fengwei1"] = "",
  ["$fengwei2"] = "",
}

fengwei:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(fengwei.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = room:askToNumber(player, {
      skill_name = fengwei.name,
      prompt = "#fengwei-choice",
      min = 1,
      max = 4,
    })
    player:drawCards(n, fengwei.name, "top", "@@fengwei-inhand-round")
  end,
})
fengwei:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.card and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@fengwei-inhand-round") > 0
      end)
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return fengwei
