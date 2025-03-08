local fengyan = fk.CreateSkill{
  name = "ol__fengyan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__fengyan"] = "讽言",
  [":ol__fengyan"] = "锁定技，当你受到其他角色造成的伤害后，或当你响应其他角色使用的牌后，你选择一项：1.你摸一张牌并交给其一张牌；"..
  "2.其摸一张牌并弃置两张牌。",

  ["ol__fengyan_self"] = "摸一张牌并交给%src一张牌",
  ["ol__fengyan_other"] = "%src摸一张牌并弃置两张牌",
  ["#ol__fengyan-card"] = "讽言：请交给 %dest 一张牌",

  ["$ol__fengyan1"] = "何不以曹公之命，换我儿之命乎？",
  ["$ol__fengyan2"] = "亲儿丧于宛城，曹公何颜复还？",
}

local fengyan_spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fengyan.name) and
      data.responseToEvent and data.responseToEvent.from and data.responseToEvent.from ~= player and
      not data.responseToEvent.from.dead then
      event:setCostData(self, {tos = {data.responseToEvent.from}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = room:askToChoice(player, {
      choices = {"ol__fengyan_self:"..to.id, "ol__fengyan_other:"..to.id},
      skill_name = fengyan.name,
    })
    if choice:startsWith("ol__fengyan_self") then
      player:drawCards(1, fengyan.name)
      if not (to.dead or player.dead or player:isNude()) then
        local cards = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = fengyan.name,
          prompt = "#ol__fengyan-card::"..to.id,
          cancelable = false,
        })
        room:moveCardTo(cards, Player.Hand, to, fk.ReasonGive, fengyan.name, nil, false, player)
      end
    else
      to:drawCards(1, fengyan.name)
      if not to.dead then
        room:askToDiscard(to, {
          min_num = 2,
          max_num = 2,
          include_equip = true,
          skill_name = fengyan.name,
          cancelable = false,
        })
      end
    end
  end,
}

fengyan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fengyan.name) and
      data.from and data.from ~= player and not data.from.dead then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = fengyan_spec.on_use,
})
fengyan:addEffect(fk.CardUseFinished, fengyan_spec)
fengyan:addEffect(fk.CardRespondFinished, fengyan_spec)

return fengyan
