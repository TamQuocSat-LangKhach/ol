local xudai = fk.CreateSkill{
  name = "xudai",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xudai"] = "虚待",
  [":xudai"] = "限定技，当你使用或打出牌响应一张牌后或受到伤害后，你可以令一名其他角色获得〖煮酒〗。",

  ["#xudai-choose"] = "虚待：你可以令一名角色获得“煮酒”",

  ["$xudai1"] = "曹公之邀，备莫敢辞。",
  ["$xudai2"] = "孟德兄以礼相待，备岂有不应之理。",
}

local xudai_spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:hasSkill("zhujiu", true)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = xudai.name,
      prompt = "#xudai-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:handleAddLoseSkills(to, "zhujiu")
  end,
}

xudai:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xudai.name) and player:usedSkillTimes(xudai.name, Player.HistoryGame) == 0 and
      table.find(player.room:getOtherPlayers(player), function (p)
        return not p:hasSkill("zhujiu", true)
      end) and
      data.responseToEvent and data.toCard
  end,
  on_cost = xudai_spec.on_cost,
  on_use = xudai_spec.on_use,
})

xudai:addEffect(fk.CardRespondFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xudai.name) and player:usedSkillTimes(xudai.name, Player.HistoryGame) == 0 and
      table.find(player.room:getOtherPlayers(player), function (p)
        return not p:hasSkill("zhujiu", true)
      end) and
      data.responseToEvent and data.responseToEvent.card
  end,
  on_cost = xudai_spec.on_cost,
  on_use = xudai_spec.on_use,
})

xudai:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xudai.name) and player:usedSkillTimes(xudai.name, Player.HistoryGame) == 0
  end,
  on_cost = xudai_spec.on_cost,
  on_use = xudai_spec.on_use,
})

return xudai
