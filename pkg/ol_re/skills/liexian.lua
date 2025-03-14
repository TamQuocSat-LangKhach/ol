local liexian = fk.CreateSkill{
  name = "ol__liexian",
}

Fk:loadTranslationTable{
  ["ol__liexian"] = "烈弦",
  [":ol__liexian"] = "当你回复体力后，若没有角色处于濒死状态，你可以令一名其他角色失去1点体力并随机使用牌堆一张装备牌。",

  ["#ol__liexian-choose"] = "烈弦：你可以令一名角色失去1点体力并使用随机装备",

  ["$ol__liexian"] = "烈火灼心，弦音刺耳。",
}

liexian:addEffect(fk.HpRecover, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liexian.name) and
      not table.find(player.room.alive_players, function(p)
        return p.dying
      end) and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = liexian.name,
      prompt = "#ol__liexian-choose",
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
    room:loseHp(to, 1, liexian.name)
    if to.dead then return end
    local cards = table.filter(room.draw_pile, function (id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and to:canUseTo(card, to)
    end)
    if #cards > 0 then
      room:useCard{
        from = to,
        tos = {to},
        card = Fk:getCardById(table.random(cards)),
      }
    end
  end,
})

return liexian
