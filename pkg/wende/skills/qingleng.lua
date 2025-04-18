local qingleng = fk.CreateSkill{
  name = "qingleng",
}

Fk:loadTranslationTable{
  ["qingleng"] = "清冷",
  [":qingleng"] = "其他角色回合结束时，若其体力值与手牌数之和不小于X，你可将一张牌当无距离限制的冰【杀】对其使用。"..
  "你对一名没有成为过〖清冷〗目标的角色发动〖清冷〗时，摸一张牌。（X为牌堆数量的个位数）",

  ["#qingleng-invoke"] = "清冷：你可以将一张牌当冰【杀】对 %dest 使用",

  ["$qingleng1"] = "冷冷清清，寂落沉沉。",
  ["$qingleng2"] = "冷月葬情，深雪埋伤。",
}

qingleng:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(qingleng.name) and not target.dead and
      (target:getHandcardNum() + target.hp >= #player.room.draw_pile % 10) and
      not (player:isNude() and #player:getHandlyIds() == 0)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "ice__slash",
      skill_name = qingleng.name,
      prompt = "#qingleng-invoke::"..target.id,
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        exclusive_targets = {target.id},
      },
      card_filter = {
        n = 1,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

qingleng:addEffect(fk.AfterCardUseDeclared, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, qingleng.name) and
      not player.dead and not table.contains(player:getTableMark(qingleng.name), player.room.current.id)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, qingleng.name, room.current.id)
    player:drawCards(1, qingleng.name)
  end,
})

return qingleng
