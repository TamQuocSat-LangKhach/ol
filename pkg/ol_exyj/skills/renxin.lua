local renxin = fk.CreateSkill{
  name = "ol_ex__renxin",
}

Fk:loadTranslationTable{
  ["ol_ex__renxin"] = "仁心",
  [":ol_ex__renxin"] = "当一名其他角色进入濒死状态时，你可以弃置一张装备牌并翻面，然后令其回复至1点体力。",

  ["#ol_ex__renxin-invoke"] = "仁心：你可以弃置一张装备牌并翻面，令 %dest 回复至1点体力",

  ["$ol_ex__renxin1"] = "待三日中，然后自归。",
  ["$ol_ex__renxin2"] = "王者仁心，尚性善之本。",
}

renxin:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(renxin.name) and target ~= player and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = renxin.name,
      cancelable = true,
      pattern = ".|.|.|.|.|equip",
      prompt = "#ol_ex__miji-invoke::"..target.id,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, renxin.name, player, player)
    if not player.dead then
      player:turnOver()
    end
    if not target.dead and target:isWounded() and target.hp < 1 then
      room:recover{
        who = target,
        num = 1 - target.hp,
        recoverBy = player,
        skillName = renxin.name,
      }
    end
  end,
})

return renxin