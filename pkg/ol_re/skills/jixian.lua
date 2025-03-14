local jixian = fk.CreateSkill{
  name = "ol__jixian",
}

Fk:loadTranslationTable{
  ["ol__jixian"] = "激弦",
  [":ol__jixian"] = "当你受到伤害后，若没有角色处于濒死状态，你可以令伤害来源失去1点体力并随机使用牌堆一张装备牌。",

  ["#ol__jixian-invoke"] = "激弦：你可以令 %dest 失去1点体力并使用随机装备",

  ["$ol__jixian"] = "曲至高亢，荡气回肠。",
}

jixian:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jixian.name) and
      data.from and not data.from.dead and
      not table.find(player.room.alive_players, function(p)
        return p.dying
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = jixian.name,
      prompt = "#ol__jixian-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(data.from, 1, jixian.name)
    if data.from.dead then return end
    local cards = table.filter(room.draw_pile, function (id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and data.from:canUseTo(card, data.from)
    end)
    if #cards > 0 then
      room:useCard{
        from = data.from,
        tos = {data.from},
        card = Fk:getCardById(table.random(cards)),
      }
    end
  end,
})

return jixian
