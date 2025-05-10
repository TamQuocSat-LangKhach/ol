local jinglei = fk.CreateSkill{
  name = "jinglei",
}

Fk:loadTranslationTable{
  ["jinglei"] = "惊雷",
  [":jinglei"] = "每回合限一次，一名角色使用【酒】结算后，若没有处于濒死状态的角色，你可以受到1点无来源的雷电伤害，令一名拥有〖煮酒〗的角色"..
  "将手牌调整至体力上限（至多摸至五张），若不为你，其将以此法弃置的牌交给你。",

  ["#jinglei-choose"] = "惊雷：你可以受到1点雷电伤害，令一名有“煮酒”的角色将手牌调整至体力上限（至多摸至五）",

  ["$jinglei1"] = "备得仕于朝，天下英雄实有未知。",
  ["$jinglei2"] = "闻惊雷而颤，备肉眼安识英雄？",
}

jinglei:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jinglei.name) and data.card.trueName == "analeptic" and
      player:usedSkillTimes(jinglei.name, Player.HistoryTurn) == 0 and
      table.find(player.room.alive_players, function (p)
        return p:hasSkill("zhujiu", true)
      end) and
      table.every(player.room.alive_players, function (p)
        return not p.dying
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:hasSkill("zhujiu", true)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = jinglei.name,
      prompt = "#jinglei-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:damage{
      to = player,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = jinglei.name,
    }
    if to.dead then return end
    local n = to:getHandcardNum() - to.maxHp
    if n > 0 then
      local cards = room:askToDiscard(to, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = jinglei.name,
        cancelable = false,
      })
      if to ~= player and not player.dead then
        cards = table.filter(cards, function (id)
          return table.contains(room.discard_pile, id)
        end)
        if #cards > 0 then
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, jinglei.name, nil, true, player)
        end
      end
    else
      n = math.min(to.maxHp, 5) - to:getHandcardNum()
      if n > 0 then
        to:drawCards(n, jinglei.name)
      end
    end
  end,
})

return jinglei
