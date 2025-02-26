local jieming = fk.CreateSkill{
  name = "ol_ex__jieming",
}

Fk:loadTranslationTable{
  ["ol_ex__jieming"] = "节命",
  [":ol_ex__jieming"] = "当你受到1点伤害后或当你死亡时，你可令一名角色摸X张牌，其将手牌弃置至X张。（X为其体力上限且至多为5）",

  ["#ol_ex__jieming-choose"] = "节命：你可以令一名角色摸X张牌并将手牌弃至X张（X为其体力上限且至多为5）",

  ["$ol_ex__jieming1"] = "含气在胸，有进无退。",
  ["$ol_ex__jieming2"] = "蕴节于形，生死无惧。",
}

local jieming_spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_ex__jieming-choose",
      skill_name = jieming.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    to:drawCards(math.min(to.maxHp, 5), jieming.name)
    if to.dead then return false end
    local x = to:getHandcardNum() - math.min(to.maxHp, 5)
    if x > 0 then
      player.room:askToDiscard(to, {
        min_num = x,
        max_num = x,
        include_equip = false,
        skill_name = jieming.name,
        cancelable = false,
      })
    end
  end,
}

jieming:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jieming.name) and player == target
  end,
  on_trigger = function(self, event, target, player, data)
    for i = 1, data.damage do
      if i > 1 and (event:isCancelCost(self) or not player:hasSkill(jieming.name)) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = jieming_spec.on_cost,
  on_use = jieming_spec.on_use,
})

jieming:addEffect(fk.Death, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_cost = jieming_spec.on_cost,
  on_use = jieming_spec.on_use,
})

return jieming