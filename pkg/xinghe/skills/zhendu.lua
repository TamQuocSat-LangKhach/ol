local zhendu = fk.CreateSkill{
  name = "ol__zhendu",
}

Fk:loadTranslationTable{
  ["ol__zhendu"] = "鸩毒",
  [":ol__zhendu"] = "一名角色的出牌阶段开始时，你可以弃置一张手牌。若如此做，该角色视为使用一张【酒】，然后若该角色不为你，你对其造成1点伤害。",

  ["#ol__zhendu-invoke"] = "鸩毒：你可以弃置一张手牌，视为 %dest 使用一张【酒】，然后你对其造成1点伤害",
  ["#ol__zhendu-self"] = "鸩毒：你可以弃置一张手牌，视为使用一张【酒】",

  ["$ol__zhendu1"] = "想要母凭子贵？你这是妄想。",
  ["$ol__zhendu2"] = "这皇宫，只能有一位储君。",
}

zhendu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhendu.name) and target.phase == Player.Play and not player:isKongcheng() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = (target == player) and "#ol__zhendu-self" or "#ol__zhendu-invoke::"..target.id
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = zhendu.name,
      prompt = prompt,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, zhendu.name, player, player)
    if not target.dead then
      room:useVirtualCard("analeptic", nil, target, target, zhendu.name, false)
    end
    if player ~= target and not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = zhendu.name,
      }
    end
  end,
})

return zhendu
