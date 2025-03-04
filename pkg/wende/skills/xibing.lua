local xibing = fk.CreateSkill{
  name = "ol__xibing",
}

Fk:loadTranslationTable{
  ["ol__xibing"] = "息兵",
  [":ol__xibing"] = "当你受到其他角色造成的伤害后，你可以弃置你或其两张牌，然后手牌数少的角色摸两张牌，以此法摸牌的角色不能使用牌"..
  "指定你为目标直到回合结束。",

  ["#ol__xibing-invoke"] = "息兵：你可以弃置你或 %dest 两张牌，然后手牌数少的角色摸两张牌",

  ["$ol__xibing1"] = "讲信修睦，息兵不功。",
  ["$ol__xibing2"] = "天时未至，周武还师。",
}

xibing:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xibing.name) and data.from and data.from ~= player and
      ((not data.from.dead and #data.from:getCardIds("he") > 1) or #player:getCardIds("he") > 1)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    if not data.from.dead and #data.from:getCardIds("he") > 1 then
      table.insert(targets, data.from)
    end
    if #table.filter(player:getCardIds("he"), function (id)
      return not player:prohibitDiscard(id)
    end) > 1 then
      table.insert(targets, player)
    end
    if #targets == 0 then
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = xibing.name,
        pattern = "false",
        prompt = "#ol__xibing-invoke::"..data.from.id,
        cancelable = true,
      })
    else
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = xibing.name,
        prompt = "#ol__xibing-invoke::"..data.from.id,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if to == player then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = xibing.name,
        cancelable = false,
      })
    else
      local cards = room:askToChooseCards(player, {
        target = to,
        min = 2,
        max = 2,
        flag = "he",
        skill_name = xibing.name,
      })
      room:throwCard(cards, xibing.name, to, player)
    end
    local p = nil
    if player:getHandcardNum() > data.from:getHandcardNum() then
      p = data.from
    elseif player:getHandcardNum() < data.from:getHandcardNum() then
      p = player
    end
    if not p or p.dead then return end
    p:drawCards(2, xibing.name)
    if not player.dead then
      room:addTableMark(player, "ol__xibing-turn", p.id)
    end
  end,
})
xibing:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and table.contains(to:getTableMark("ol__xibing-turn"), from.id)
  end,
})

return xibing
